;; Time-Locked Wallet with Enhanced Security and Features
;; Owner management with transfer capability
(define-data-var owner principal tx-sender)
(define-data-var pending-owner (optional principal) none)
(define-data-var unlock-block uint u10000)

;; Track deposits and withdrawals
(define-data-var total-deposited uint u0)
(define-data-var total-withdrawn uint u0)

;; Emergency unlock state - using a map instead of data-var to avoid interdependencies
(define-map emergency-state bool bool)

;; Constants for error codes
(define-constant ERR-NOT-OWNER (err u401))
(define-constant ERR-NOT-UNLOCKED (err u403))
(define-constant ERR-INSUFFICIENT-BALANCE (err u404))
(define-constant ERR-INVALID-AMOUNT (err u405))
(define-constant ERR-INVALID-BLOCK (err u406))
(define-constant ERR-EMERGENCY-ACTIVE (err u407))
(define-constant ERR-NOT-PENDING-OWNER (err u408))

;; Events
(define-map deposits uint {depositor: principal, amount: uint, block: uint})
(define-map withdrawals uint {recipient: principal, amount: uint, block: uint})
(define-data-var deposit-counter uint u0)
(define-data-var withdrawal-counter uint u0)

;; Helper function to check emergency status
(define-private (get-emergency-unlock-status)
  (default-to false (map-get? emergency-state true)))

;; Read-only functions
(define-read-only (get-owner)
  (var-get owner))

(define-read-only (get-pending-owner)
  (var-get pending-owner))

(define-read-only (get-unlock-block)
  (var-get unlock-block))

(define-read-only (get-balance)
  (stx-get-balance (as-contract tx-sender)))

(define-read-only (get-total-deposited)
  (var-get total-deposited))

(define-read-only (get-total-withdrawn)
  (var-get total-withdrawn))

(define-read-only (get-emergency-status)
  (get-emergency-unlock-status))

(define-read-only (blocks-until-unlock)
  (if (>= block-height (var-get unlock-block))
      u0
      (- (var-get unlock-block) block-height)))

(define-read-only (get-deposit (id uint))
  (map-get? deposits id))

(define-read-only (get-withdrawal (id uint))
  (map-get? withdrawals id))

;; Owner management functions
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) ERR-NOT-OWNER)
    (var-set pending-owner (some new-owner))
    (ok new-owner)))

(define-public (accept-ownership)
  (let ((pending (var-get pending-owner)))
    (asserts! (is-some pending) ERR-NOT-PENDING-OWNER)
    (asserts! (is-eq tx-sender (unwrap-panic pending)) ERR-NOT-PENDING-OWNER)
    (var-set owner tx-sender)
    (var-set pending-owner none)
    (ok tx-sender)))

;; Lock management functions
(define-public (set-unlock-block (block uint))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) ERR-NOT-OWNER)
    (asserts! (> block block-height) ERR-INVALID-BLOCK)
    (asserts! (not (get-emergency-unlock-status)) ERR-EMERGENCY-ACTIVE)
    (var-set unlock-block block)
    (ok block)))

(define-public (emergency-unlock)
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) ERR-NOT-OWNER)
    (map-set emergency-state true true)
    (ok true)))

(define-public (disable-emergency-unlock)
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) ERR-NOT-OWNER)
    (map-delete emergency-state true)
    (ok false)))

;; Deposit function
(define-public (deposit (amount uint))
  (let ((deposit-id (+ (var-get deposit-counter) u1)))
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set total-deposited (+ (var-get total-deposited) amount))
    (var-set deposit-counter deposit-id)
    (map-set deposits deposit-id {
      depositor: tx-sender,
      amount: amount,
      block: block-height
    })
    (ok deposit-id)))

;; Withdraw function
(define-public (withdraw (amount uint) (recipient principal))
  (let ((current-balance (stx-get-balance (as-contract tx-sender)))
        (withdrawal-id (+ (var-get withdrawal-counter) u1))
        (emergency-active (get-emergency-unlock-status)))
    (asserts! (is-eq tx-sender (var-get owner)) ERR-NOT-OWNER)
    (asserts! (or (>= block-height (var-get unlock-block)) emergency-active) ERR-NOT-UNLOCKED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (>= current-balance amount) ERR-INSUFFICIENT-BALANCE)
    (try! (as-contract (stx-transfer? amount tx-sender recipient)))
    (var-set total-withdrawn (+ (var-get total-withdrawn) amount))
    (var-set withdrawal-counter withdrawal-id)
    (map-set withdrawals withdrawal-id {
      recipient: recipient,
      amount: amount,
      block: block-height
    })
    (ok withdrawal-id)))

;; Withdraw all available funds
(define-public (withdraw-all (recipient principal))
  (let ((current-balance (stx-get-balance (as-contract tx-sender)))
        (withdrawal-id (+ (var-get withdrawal-counter) u1))
        (emergency-active (get-emergency-unlock-status)))
    (asserts! (is-eq tx-sender (var-get owner)) ERR-NOT-OWNER)
    (asserts! (or (>= block-height (var-get unlock-block)) emergency-active) ERR-NOT-UNLOCKED)
    (asserts! (> current-balance u0) ERR-INVALID-AMOUNT)
    (try! (as-contract (stx-transfer? current-balance tx-sender recipient)))
    (var-set total-withdrawn (+ (var-get total-withdrawn) current-balance))
    (var-set withdrawal-counter withdrawal-id)
    (map-set withdrawals withdrawal-id {
      recipient: recipient,
      amount: current-balance,
      block: block-height
    })
    (ok withdrawal-id)))
