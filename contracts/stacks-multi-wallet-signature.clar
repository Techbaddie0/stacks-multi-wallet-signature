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

;; Function to set daily spending limit for an owner
(define-public (set-daily-spending-limit 
  (owner principal) 
  (limit uint)
)
  (begin
    (asserts! (is-owner tx-sender) ERR-NOT-OWNER)
    (map-set daily-spending-limits owner limit)
    (ok true)
  )
)

;; Function to add a new owner
(define-public (add-owner (new-owner principal))
  (let 
    (
      (current-owners (var-get owners))
    )
    (asserts! (is-owner tx-sender) ERR-NOT-OWNER)
    (asserts! 
      (is-none (index-of current-owners new-owner)) 
      ERR-INVALID-TX
    )

    (var-set owners 
      (unwrap-panic 
        (as-max-len? (append current-owners new-owner) u10)
      )
    )
    (ok true)
  )
)

;; Variable to track current block height
(define-data-var current-block-height uint u0)

;; Function to increment block height
(define-public (increment-block-height)
    (begin
        (var-set current-block-height 
            (+ (var-get current-block-height) u1)
        )
        (ok true)
    )
)

;; Function to get current block height
(define-read-only (get-block-height)
    (var-get current-block-height)
)

;; Function to manually set block height (useful for testing or initialization)
(define-public (set-block-height (new-height uint))
    (begin
        (var-set current-block-height new-height)
        (ok true)
    )
)

;; Propose a new transaction
(define-public (propose-transaction (recipient principal) (amount uint))
  (let 
    (
      (tx-id (var-get tx-count))
      (new-tx {
        recipient: recipient, 
        amount: amount, 
        signatures: (list tx-sender), 
        executed: false
      })
    )
    (asserts! (is-owner tx-sender) ERR-NOT-OWNER)
    (map-set transactions tx-id new-tx)
    (var-set tx-count (+ tx-id u1))
    (ok tx-id)
  )
)

;; Sign a transaction
(define-public (sign-transaction (tx-id uint))
  (let 
    (
      (tx (unwrap! (map-get? transactions tx-id) ERR-INVALID-TX))
      (updated-tx (merge tx {
        signatures: (if (is-owner tx-sender)
                        (unwrap-panic (as-max-len? (append (get signatures tx) tx-sender) u10))
                        (get signatures tx))
      }))
    )
    (asserts! (is-owner tx-sender) ERR-NOT-OWNER)
    (map-set transactions tx-id updated-tx)
    (ok true)
  )
)

;; Execute a transaction
(define-public (execute-transaction (tx-id uint))
  (let 
    (
      (tx (unwrap! (map-get? transactions tx-id) ERR-INVALID-TX))
    )
    (asserts! (is-owner tx-sender) ERR-NOT-OWNER)
    (asserts! (not (get executed tx)) ERR-INVALID-TX)
    (asserts! 
      (>= (len (get signatures tx)) (var-get threshold)) 
      ERR-NOT-ENOUGH-SIGS
    )

    ;; Transfer STX and mark transaction as executed
    (try! (stx-transfer? 
      (get amount tx) 
      tx-sender 
      (get recipient tx)
    ))

    (map-set transactions tx-id 
      (merge tx {executed: true})
    )
    (ok true)
  )
)

;; Create a timelocked withdrawal
(define-public (create-timelocked-withdrawal 
  (recipient principal) 
  (amount uint) 
  (lock-period uint)
)
  (let 
    (
      (tx-id (var-get tx-count))
      (release-block (+ (var-get current-block-height) lock-period))
    )
    (asserts! (is-owner tx-sender) ERR-NOT-OWNER)

    (map-set timelock-withdrawals tx-id {
      recipient: recipient,
      amount: amount,
      release-block: release-block,
      approved: false
    })

    (var-set tx-count (+ tx-id u1))
    (ok tx-id)
  )
)

;; Approve timelocked withdrawal
(define-public (approve-timelocked-withdrawal (tx-id uint))
  (let 
    (
      (withdrawal 
        (unwrap! 
          (map-get? timelock-withdrawals tx-id) 
          ERR-INVALID-TX
        )
      )
    )
    (asserts! (is-owner tx-sender) ERR-NOT-OWNER)

    (map-set timelock-withdrawals tx-id 
      (merge withdrawal { approved: true })
    )
    (ok true)
  )
)

;; Execute timelocked withdrawal
(define-public (execute-timelocked-withdrawal (tx-id uint))
  (let 
    (
      (withdrawal 
        (unwrap! 
          (map-get? timelock-withdrawals tx-id) 
          ERR-INVALID-TX
        )
      )
    )
    ;; Check if withdrawal is approved and time has passed
    (asserts! (get approved withdrawal) ERR-INVALID-TX)
    (asserts! 
      (>= (var-get current-block-height) (get release-block withdrawal)) 
      ERR-INVALID-TX
    )

    ;; Transfer funds
    (try! 
      (stx-transfer? 
        (get amount withdrawal) 
        tx-sender 
        (get recipient withdrawal)
      )
    )

    (ok true)
  )
)

;; Additional read-only functions for new features
(define-read-only (get-daily-spending-limit (owner principal))
  (map-get? daily-spending-limits owner)
)

(define-read-only (get-timelocked-withdrawal (tx-id uint))
  (map-get? timelock-withdrawals tx-id)
)