(define-data-var owner principal tx-sender)
(define-data-var unlock-block uint u10000)

(define-public (set-unlock-block (block uint))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err u401))
    (var-set unlock-block block)
    (ok block)))

(define-public (deposit)
  (ok true))

(define-public (withdraw (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err u401))
    (asserts! (>= block-height (var-get unlock-block)) (err u403))
    (stx-transfer? amount tx-sender recipient)))
