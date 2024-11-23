;; milestone-funding contract

;; Constants
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_MILESTONE (err u101))
(define-constant ERR_ALREADY_FUNDED (err u102))
(define-constant ERR_MILESTONE_NOT_COMPLETE (err u103))
(define-constant ERR_INSUFFICIENT_FUNDS (err u104))

;; Data vars
(define-data-var project-owner principal tx-sender)
(define-data-var total-funds uint u0)
(define-data-var current-milestone uint u0)

;; Data maps
(define-map milestones uint {
    description: (string-ascii 256),
    funds-required: uint,
    completed: bool,
    funded: bool
})

;; Public functions
(define-public (add-milestone (description (string-ascii 256)) (funds-required uint))
    (begin
        (asserts! (is-eq tx-sender (var-get project-owner)) ERR_UNAUTHORIZED)
        (map-set milestones (+ (var-get current-milestone) u1) 
            {
                description: description,
                funds-required: funds-required,
                completed: false,
                funded: false
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
        (map-set milestones milestone-id (merge milestone {funded: true}))
        (ok true)
    )
)

(define-public (complete-milestone (milestone-id uint))
    (let (
        (milestone (unwrap! (map-get? milestones milestone-id) ERR_INVALID_MILESTONE))
    )
        (asserts! (is-eq tx-sender (var-get project-owner)) ERR_UNAUTHORIZED)
        (asserts! (get funded milestone) ERR_MILESTONE_NOT_COMPLETE)
        (try! (as-contract (stx-transfer? (get funds-required milestone) tx-sender (var-get project-owner))))
        (map-set milestones milestone-id (merge milestone {completed: true}))
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
