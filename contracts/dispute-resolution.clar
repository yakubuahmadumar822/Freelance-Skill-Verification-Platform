;; Define constants
(define-constant contract-owner tx-sender)
(define-constant arbitration-fee u100) ;; in STX

;; Define data vars and maps
(define-map disputes
  { dispute-id: uint }
  { client: principal, freelancer: principal, amount: uint, status: (string-ascii 20) })

(define-map arbitrators principal bool)

(define-data-var dispute-nonce uint u0)

;; Define public functions
(define-public (create-dispute (client principal) (freelancer principal) (amount uint))
  (let ((dispute-id (var-get dispute-nonce)))
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set disputes { dispute-id: dispute-id }
                      { client: client,
                        freelancer: freelancer,
                        amount: amount,
                        status: "OPEN" })
    (var-set dispute-nonce (+ dispute-id u1))
    (ok dispute-id)))

(define-public (resolve-dispute (dispute-id uint) (winner principal))
  (let ((dispute (unwrap! (map-get? disputes { dispute-id: dispute-id }) (err u404))))
    (asserts! (is-eq (get status dispute) "OPEN") (err u403))
    (asserts! (is-some (index-of? (list (get client dispute) (get freelancer dispute)) winner)) (err u403))
    (try! (as-contract (stx-transfer? (get amount dispute) tx-sender winner)))
    (map-set disputes { dispute-id: dispute-id }
                      (merge dispute { status: "RESOLVED" }))
    (ok true)))

(define-public (register-as-arbitrator)
  (begin
    (try! (stx-transfer? arbitration-fee tx-sender (as-contract tx-sender)))
    (map-set arbitrators tx-sender true)
    (ok true)))

;; Define read-only functions
(define-read-only (get-dispute (dispute-id uint))
  (map-get? disputes { dispute-id: dispute-id }))

(define-read-only (is-arbitrator (account principal))
  (default-to false (map-get? arbitrators account)))

;; Define private functions
(define-private (is-owner)
  (is-eq tx-sender contract-owner))

