;; milestone-funding contract

;; Constants
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_MILESTONE (err u101))
(define-constant ERR_ALREADY_FUNDED (err u102))
(define-constant ERR_MILESTONE_NOT_COMPLETE (err u103))
(define-constant ERR_INSUFFICIENT_FUNDS (err u104))
(define-constant ERR_ALREADY_VOTED (err u105))
(define-constant ERR_REFUND_PERIOD_ACTIVE (err u106))
(define-constant ERR_NO_REFUND_AVAILABLE (err u107))

;; Data vars
(define-data-var project-owner principal tx-sender)
(define-data-var total-funds uint u0)
(define-data-var current-milestone uint u0)
(define-data-var refund-period-blocks uint u100)

;; Data maps
(define-map milestones uint {
    description: (string-ascii 256),
    funds-required: uint,
    completed: bool,
    funded: bool,
    vote-count: uint,
    vote-threshold: uint
})

(define-map milestone-funders { milestone-id: uint, funder: principal } uint)
(define-map milestone-votes { milestone-id: uint, voter: principal } bool)

;; Public functions
(define-public (add-milestone (description (string-ascii 256)) (funds-required uint) (vote-threshold uint))
    (begin
        (asserts! (is-eq tx-sender (var-get project-owner)) ERR_UNAUTHORIZED)
        (map-set milestones (+ (var-get current-milestone) u1) 
            {
                description: description,
                funds-required: funds-required,
                completed: false,
                funded: false,
                vote-count: u0,
                vote-threshold: vote-threshold
            }
        )
        (var-set current-milestone (+ (var-get current-milestone) u1))
        (ok true)
    )
)

(define-public (fund-milestone (milestone-id uint)) 
    (let (
        (milestone (unwrap! (map-get? milestones milestone-id) ERR_INVALID_MILESTONE))
    )
        (asserts! (not (get funded milestone)) ERR_ALREADY_FUNDED)
        (asserts! (>= (stx-get-balance tx-sender) (get funds-required milestone)) ERR_INSUFFICIENT_FUNDS)
        (try! (stx-transfer? (get funds-required milestone) tx-sender (as-contract tx-sender)))
        (var-set total-funds (+ (var-get total-funds) (get funds-required milestone)))
        (map-set milestone-funders { milestone-id: milestone-id, funder: tx-sender } (get funds-required milestone))
        (map-set milestones milestone-id (merge milestone {funded: true}))
        (ok true)
    )
)

(define-public (vote-milestone (milestone-id uint))
    (let (
        (milestone (unwrap! (map-get? milestones milestone-id) ERR_INVALID_MILESTONE))
        (has-voted (default-to false (map-get? milestone-votes { milestone-id: milestone-id, voter: tx-sender })))
    )
        (asserts! (not has-voted) ERR_ALREADY_VOTED)
        (map-set milestone-votes { milestone-id: milestone-id, voter: tx-sender } true)
        (map-set milestones milestone-id 
            (merge milestone {vote-count: (+ (get vote-count milestone) u1)})
        )
        (ok true)
    )
)

(define-public (complete-milestone (milestone-id uint))
    (let (
        (milestone (unwrap! (map-get? milestones milestone-id) ERR_INVALID_MILESTONE))
    )
        (asserts! (is-eq tx-sender (var-get project-owner)) ERR_UNAUTHORIZED)
        (asserts! (get funded milestone) ERR_MILESTONE_NOT_COMPLETE)
        (asserts! (>= (get vote-count milestone) (get vote-threshold milestone)) ERR_MILESTONE_NOT_COMPLETE)
        (try! (as-contract (stx-transfer? (get funds-required milestone) tx-sender (var-get project-owner))))
        (map-set milestones milestone-id (merge milestone {completed: true}))
        (ok true)
    )
)

(define-public (request-refund (milestone-id uint))
    (let (
        (milestone (unwrap! (map-get? milestones milestone-id) ERR_INVALID_MILESTONE))
        (user-contribution (unwrap! (map-get? milestone-funders { milestone-id: milestone-id, funder: tx-sender }) ERR_NO_REFUND_AVAILABLE))
    )
        (asserts! (< block-height (+ block-height (var-get refund-period-blocks))) ERR_REFUND_PERIOD_ACTIVE)
        (try! (as-contract (stx-transfer? user-contribution tx-sender tx-sender)))
        (map-delete milestone-funders { milestone-id: milestone-id, funder: tx-sender })
        (ok true)
    )
)

;; Read only functions 
(define-read-only (get-milestone (milestone-id uint))
    (map-get? milestones milestone-id)
)

(define-read-only (get-total-funds)
    (ok (var-get total-funds))
)

(define-read-only (get-current-milestone)
    (ok (var-get current-milestone))
)

(define-read-only (get-funder-contribution (milestone-id uint) (funder principal))
    (map-get? milestone-funders { milestone-id: milestone-id, funder: funder })
)
