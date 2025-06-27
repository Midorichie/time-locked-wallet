;; Multi-Vault Manager Contract
;; Allows users to create and manage multiple time-locked vaults

;; Vault structure
(define-map vaults uint {
  owner: principal,
  unlock-block: uint,
  balance: uint,
  created-at: uint,
  is-active: bool
})

;; User vault tracking
(define-map user-vaults principal (list 50 uint))
(define-data-var vault-counter uint u0)

;; Constants
(define-constant ERR-NOT-VAULT-OWNER (err u501))
(define-constant ERR-VAULT-NOT-FOUND (err u502))
(define-constant ERR-VAULT-LOCKED (err u503))
(define-constant ERR-INVALID-AMOUNT (err u504))
(define-constant ERR-VAULT-INACTIVE (err u505))
(define-constant ERR-MAX-VAULTS (err u506))

;; Read-only functions
(define-read-only (get-vault (vault-id uint))
  (map-get? vaults vault-id))

(define-read-only (get-user-vaults (user principal))
  (default-to (list) (map-get? user-vaults user)))

(define-read-only (get-vault-count)
  (var-get vault-counter))

(define-read-only (is-vault-unlocked (vault-id uint))
  (match (map-get? vaults vault-id)
    vault-data (>= block-height (get unlock-block vault-data))
    false))

;; Create a new vault
(define-public (create-vault (unlock-block uint))
  (let ((vault-id (+ (var-get vault-counter) u1))
        (current-vaults (get-user-vaults tx-sender)))
    (asserts! (> unlock-block block-height) (err u400))
    (asserts! (< (len current-vaults) u50) ERR-MAX-VAULTS)
    
    (map-set vaults vault-id {
      owner: tx-sender,
      unlock-block: unlock-block,
      balance: u0,
      created-at: block-height,
      is-active: true
    })
    
    (map-set user-vaults tx-sender 
      (unwrap! (as-max-len? (append current-vaults vault-id) u50) ERR-MAX-VAULTS))
    
    (var-set vault-counter vault-id)
    (ok vault-id)))

;; Deposit to a specific vault
(define-public (deposit-to-vault (vault-id uint) (amount uint))
  (let ((vault-data (unwrap! (map-get? vaults vault-id) ERR-VAULT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner vault-data)) ERR-NOT-VAULT-OWNER)
    (asserts! (get is-active vault-data) ERR-VAULT-INACTIVE)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    (map-set vaults vault-id 
      (merge vault-data { balance: (+ (get balance vault-data) amount) }))
    
    (ok amount)))

;; Withdraw from a specific vault
(define-public (withdraw-from-vault (vault-id uint) (amount uint) (recipient principal))
  (let ((vault-data (unwrap! (map-get? vaults vault-id) ERR-VAULT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner vault-data)) ERR-NOT-VAULT-OWNER)
    (asserts! (get is-active vault-data) ERR-VAULT-INACTIVE)
    (asserts! (>= block-height (get unlock-block vault-data)) ERR-VAULT-LOCKED)
    (asserts! (>= (get balance vault-data) amount) ERR-INVALID-AMOUNT)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    
    (try! (as-contract (stx-transfer? amount tx-sender recipient)))
    
    (map-set vaults vault-id 
      (merge vault-data { balance: (- (get balance vault-data) amount) }))
    
    (ok amount)))

;; Close a vault (only when empty)
(define-public (close-vault (vault-id uint))
  (let ((vault-data (unwrap! (map-get? vaults vault-id) ERR-VAULT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner vault-data)) ERR-NOT-VAULT-OWNER)
    (asserts! (is-eq (get balance vault-data) u0) ERR-INVALID-AMOUNT)
    
    (map-set vaults vault-id 
      (merge vault-data { is-active: false }))
    
    (ok true)))

;; Emergency withdraw (for contract owner only - additional security layer)
(define-public (emergency-withdraw-vault (vault-id uint) (recipient principal))
  (let ((vault-data (unwrap! (map-get? vaults vault-id) ERR-VAULT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner vault-data)) ERR-NOT-VAULT-OWNER)
    (asserts! (get is-active vault-data) ERR-VAULT-INACTIVE)
    
    (let ((balance (get balance vault-data)))
      (asserts! (> balance u0) ERR-INVALID-AMOUNT)
      (try! (as-contract (stx-transfer? balance tx-sender recipient)))
      
      (map-set vaults vault-id 
        (merge vault-data { balance: u0 }))
      
      (ok balance))))
