;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u404))
(define-constant err-unauthorized (err u401))
(define-constant err-already-exists (err u402))

;; Define NFT for skill badges
(define-non-fungible-token skill-badge uint)

;; Define data vars and maps
(define-map skills
  { skill-id: uint }
  { name: (string-ascii 64),
    description: (string-ascii 256),
    difficulty: uint })

(define-map freelancer-skills
  { freelancer: principal, skill-id: uint }
  { badge-id: uint,
    endorsements: uint })

(define-map endorsements
  { endorser: principal, freelancer: principal, skill-id: uint }
  { timestamp: uint })

(define-data-var skill-nonce uint u0)
(define-data-var badge-nonce uint u0)

;; Define public functions
(define-public (add-skill (name (string-ascii 64)) (description (string-ascii 256)) (difficulty uint))
  (let ((skill-id (var-get skill-nonce)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set skills
      { skill-id: skill-id }
      { name: name,
        description: description,
        difficulty: difficulty })
    (var-set skill-nonce (+ skill-id u1))
    (ok skill-id)))

(define-public (verify-skill (skill-id uint))
  (let ((skill (unwrap! (map-get? skills { skill-id: skill-id }) err-not-found))
        (badge-id (var-get badge-nonce)))
    (asserts! (is-none (map-get? freelancer-skills { freelancer: tx-sender, skill-id: skill-id })) err-already-exists)
    (try! (nft-mint? skill-badge badge-id tx-sender))
    (map-set freelancer-skills
      { freelancer: tx-sender, skill-id: skill-id }
      { badge-id: badge-id,
        endorsements: u0 })
    (var-set badge-nonce (+ badge-id u1))
    (ok badge-id)))

(define-public (endorse-skill (freelancer principal) (skill-id uint))
  (let ((freelancer-skill (unwrap! (map-get? freelancer-skills { freelancer: freelancer, skill-id: skill-id }) err-not-found)))
    (asserts! (not (is-eq tx-sender freelancer)) err-unauthorized)
    (asserts! (is-none (map-get? endorsements { endorser: tx-sender, freelancer: freelancer, skill-id: skill-id })) err-already-exists)
    (map-set endorsements
      { endorser: tx-sender, freelancer: freelancer, skill-id: skill-id }
      { timestamp: block-height })
    (map-set freelancer-skills
      { freelancer: freelancer, skill-id: skill-id }
      (merge freelancer-skill { endorsements: (+ (get endorsements freelancer-skill) u1) }))
    (ok true)))

(define-public (revoke-endorsement (freelancer principal) (skill-id uint))
  (let ((freelancer-skill (unwrap! (map-get? freelancer-skills { freelancer: freelancer, skill-id: skill-id }) err-not-found))
        (endorsement (unwrap! (map-get? endorsements { endorser: tx-sender, freelancer: freelancer, skill-id: skill-id }) err-not-found)))
    (map-delete endorsements { endorser: tx-sender, freelancer: freelancer, skill-id: skill-id })
    (map-set freelancer-skills
      { freelancer: freelancer, skill-id: skill-id }
      (merge freelancer-skill { endorsements: (- (get endorsements freelancer-skill) u1) }))
    (ok true)))

;; Define read-only functions
(define-read-only (get-skill (skill-id uint))
  (map-get? skills { skill-id: skill-id }))

(define-read-only (get-freelancer-skill (freelancer principal) (skill-id uint))
  (map-get? freelancer-skills { freelancer: freelancer, skill-id: skill-id }))

(define-read-only (get-endorsement (endorser principal) (freelancer principal) (skill-id uint))
  (map-get? endorsements { endorser: endorser, freelancer: freelancer, skill-id: skill-id }))

;; Define private functions
(define-private (is-owner)
  (is-eq tx-sender contract-owner))

