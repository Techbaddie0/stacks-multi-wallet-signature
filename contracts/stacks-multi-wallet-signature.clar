;; Stacks Multi-Signature Wallet Contract

(define-constant ERR-NOT-OWNER (err u100))
(define-constant ERR-INVALID-TX (err u101))
(define-constant ERR-NOT-ENOUGH-SIGS (err u102))
(define-constant ERR-WALLET-ALREADY-INITIALIZED (err u103))
(define-constant ERR-CANNOT-REMOVE-OWNER (err u104))
(define-constant ERR-INVALID-THRESHOLD (err u105))
(define-constant contract-owner tx-sender)

(define-data-var threshold uint u2)

(define-data-var owners (list 10 principal) (list))
(define-data-var tx-count uint u0)

;; Add a new map for tracking daily spending limits
(define-map daily-spending-limits principal uint)

;; Add a map to track daily accumulated spending
(define-map daily-spending-tracker 
  { 
    owner: principal, 
    timestamp: uint 
  } 
  uint
)

;; Add timelocked withdrawal capability
(define-map timelock-withdrawals
  uint
  {
    recipient: principal,
    amount: uint,
    release-block: uint,
    approved: bool
  }
)

;; Transaction structure
(define-map transactions 
  uint 
  {
    recipient: principal, 
    amount: uint, 
    signatures: (list 10 principal),
    executed: bool
  }
)

;; Check if an account is an owner
(define-private (is-owner (account principal))
  (is-some (index-of (var-get owners) account))
)

;; Read-only functions for wallet information
(define-read-only (get-transaction (tx-id uint))
  (map-get? transactions tx-id)
)

(define-read-only (get-wallet-owners)
  (var-get owners)
)

(define-read-only (get-signature-threshold)
  (var-get threshold)
)

;; Read-only function to check if an account is an owner
(define-read-only (is-wallet-owner (account principal))
  (is-owner account)
)

;; Initialize the wallet
(define-public (initialize-wallet (wallet-owners (list 10 principal)) (sig-threshold uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-NOT-OWNER)
    (asserts! (> sig-threshold u0) ERR-NOT-OWNER)
    (var-set owners wallet-owners)
    (var-set threshold sig-threshold)
    (ok true)
  )
)
