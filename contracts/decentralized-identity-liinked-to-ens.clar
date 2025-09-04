(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-domain-exists (err u101))
(define-constant err-domain-not-found (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-domain (err u104))
(define-constant err-identity-not-found (err u105))
(define-constant err-invalid-data (err u106))
(define-constant err-domain-expired (err u107))
(define-constant err-insufficient-payment (err u108))
(define-constant err-domain-not-expired (err u109))

(define-map domains 
  { domain: (string-ascii 63) }
  { 
    owner: principal,
    resolver: principal,
    ttl: uint,
    created-at: uint,
    updated-at: uint,
    expires-at: uint,
    renewal-period: uint
  })

(define-map identity-profiles
  { owner: principal }
  {
    primary-domain: (optional (string-ascii 63)),
    display-name: (string-utf8 64),
    avatar: (string-ascii 256),
    email: (string-ascii 128),
    website: (string-ascii 256),
    bio: (string-utf8 280),
    github: (string-ascii 39),
    twitter: (string-ascii 15),
    discord: (string-ascii 37),
    created-at: uint,
    updated-at: uint
  })

(define-map domain-records
  { domain: (string-ascii 63), record-type: (string-ascii 10) }
  { value: (string-ascii 256), ttl: uint })

(define-map domain-resolvers
  { domain: (string-ascii 63) }
  { resolver-address: (string-ascii 42) })

(define-data-var total-domains uint u0)
(define-data-var registration-fee uint u1000000)
(define-data-var min-domain-length uint u3)
(define-data-var max-domain-length uint u63)
(define-data-var default-renewal-period uint u52560)
(define-data-var renewal-fee uint u500000)
(define-data-var grace-period uint u1440)

(define-private (is-valid-domain (domain (string-ascii 63)))
  (let ((domain-len (len domain)))
    (and 
      (>= domain-len (var-get min-domain-length))
      (<= domain-len (var-get max-domain-length))
      (not (is-eq domain "")))))

(define-private (domain-available (domain (string-ascii 63)))
  (is-none (map-get? domains { domain: domain })))

(define-private (is-domain-expired (domain (string-ascii 63)))
  (match (map-get? domains { domain: domain })
    domain-info (> stacks-block-height (get expires-at domain-info))
    true))

(define-private (is-in-grace-period (domain (string-ascii 63)))
  (match (map-get? domains { domain: domain })
    domain-info 
      (let ((expires-at (get expires-at domain-info))
            (grace-end (+ expires-at (var-get grace-period))))
        (and 
          (> stacks-block-height expires-at)
          (<= stacks-block-height grace-end)))
    false))

(define-public (register-domain (domain (string-ascii 63)) (ttl uint))
  (let ((current-block stacks-block-height)
        (renewal-period (var-get default-renewal-period))
        (expires-at (+ current-block renewal-period)))
    (asserts! (is-valid-domain domain) err-invalid-domain)
    (asserts! (domain-available domain) err-domain-exists)
    (map-set domains 
      { domain: domain }
      {
        owner: tx-sender,
        resolver: tx-sender,
        ttl: ttl,
        created-at: current-block,
        updated-at: current-block,
        expires-at: expires-at,
        renewal-period: renewal-period
      })
    (var-set total-domains (+ (var-get total-domains) u1))
    (ok domain)))

(define-public (transfer-domain (domain (string-ascii 63)) (new-owner principal))
  (let ((domain-info (unwrap! (map-get? domains { domain: domain }) err-domain-not-found)))
    (asserts! (is-eq (get owner domain-info) tx-sender) err-unauthorized)
    (map-set domains 
      { domain: domain }
      (merge domain-info { 
        owner: new-owner, 
        updated-at: stacks-block-height 
      }))
    (ok true)))

(define-public (set-domain-resolver (domain (string-ascii 63)) (resolver principal))
  (let ((domain-info (unwrap! (map-get? domains { domain: domain }) err-domain-not-found)))
    (asserts! (is-eq (get owner domain-info) tx-sender) err-unauthorized)
    (map-set domains 
      { domain: domain }
      (merge domain-info { 
        resolver: resolver, 
        updated-at: stacks-block-height 
      }))
    (ok true)))

(define-public (renew-domain (domain (string-ascii 63)) (additional-period uint))
  (let ((domain-info (unwrap! (map-get? domains { domain: domain }) err-domain-not-found))
        (current-block stacks-block-height)
        (renewal-cost (var-get renewal-fee)))
    (asserts! (is-eq (get owner domain-info) tx-sender) err-unauthorized)
    (asserts! (not (and (is-domain-expired domain) (not (is-in-grace-period domain)))) err-domain-expired)
    (map-set domains 
      { domain: domain }
      (merge domain-info { 
        expires-at: (+ (get expires-at domain-info) additional-period),
        updated-at: current-block
      }))
    (ok true)))

(define-public (reclaim-expired-domain (domain (string-ascii 63)) (ttl uint))
  (let ((current-block stacks-block-height)
        (renewal-period (var-get default-renewal-period))
        (expires-at (+ current-block renewal-period)))
    (asserts! (is-valid-domain domain) err-invalid-domain)
    (asserts! (is-domain-expired domain) err-domain-not-expired)
    (asserts! (not (is-in-grace-period domain)) err-domain-not-expired)
    (map-set domains 
      { domain: domain }
      {
        owner: tx-sender,
        resolver: tx-sender,
        ttl: ttl,
        created-at: current-block,
        updated-at: current-block,
        expires-at: expires-at,
        renewal-period: renewal-period
      })
    (ok domain)))

(define-public (set-domain-record (domain (string-ascii 63)) (record-type (string-ascii 10)) (value (string-ascii 256)) (ttl uint))
  (let ((domain-info (unwrap! (map-get? domains { domain: domain }) err-domain-not-found)))
    (asserts! (not (is-domain-expired domain)) err-domain-expired)
    (asserts! (or 
      (is-eq (get owner domain-info) tx-sender)
      (is-eq (get resolver domain-info) tx-sender)) err-unauthorized)
    (map-set domain-records
      { domain: domain, record-type: record-type }
      { value: value, ttl: ttl })
    (ok true)))

(define-public (set-resolver-address (domain (string-ascii 63)) (resolver-address (string-ascii 42)))
  (let ((domain-info (unwrap! (map-get? domains { domain: domain }) err-domain-not-found)))
    (asserts! (is-eq (get resolver domain-info) tx-sender) err-unauthorized)
    (map-set domain-resolvers
      { domain: domain }
      { resolver-address: resolver-address })
    (ok true)))

(define-public (create-identity-profile 
  (display-name (string-utf8 64))
  (avatar (string-ascii 256))
  (email (string-ascii 128))
  (website (string-ascii 256))
  (bio (string-utf8 280))
  (github (string-ascii 39))
  (twitter (string-ascii 15))
  (discord (string-ascii 37)))
  (let ((current-block stacks-block-height))
    (map-set identity-profiles
      { owner: tx-sender }
      {
        primary-domain: none,
        display-name: display-name,
        avatar: avatar,
        email: email,
        website: website,
        bio: bio,
        github: github,
        twitter: twitter,
        discord: discord,
        created-at: current-block,
        updated-at: current-block
      })
    (ok true)))

(define-public (update-identity-profile
  (display-name (string-utf8 64))
  (avatar (string-ascii 256))
  (email (string-ascii 128))
  (website (string-ascii 256))
  (bio (string-utf8 280))
  (github (string-ascii 39))
  (twitter (string-ascii 15))
  (discord (string-ascii 37)))
  (let ((current-profile (unwrap! (map-get? identity-profiles { owner: tx-sender }) err-identity-not-found)))
    (map-set identity-profiles
      { owner: tx-sender }
      (merge current-profile {
        display-name: display-name,
        avatar: avatar,
        email: email,
        website: website,
        bio: bio,
        github: github,
        twitter: twitter,
        discord: discord,
        updated-at: stacks-block-height
      }))
    (ok true)))

(define-public (set-primary-domain (domain (string-ascii 63)))
  (let ((domain-info (unwrap! (map-get? domains { domain: domain }) err-domain-not-found))
        (current-profile (unwrap! (map-get? identity-profiles { owner: tx-sender }) err-identity-not-found)))
    (asserts! (is-eq (get owner domain-info) tx-sender) err-unauthorized)
    (map-set identity-profiles
      { owner: tx-sender }
      (merge current-profile { 
        primary-domain: (some domain),
        updated-at: stacks-block-height
      }))
    (ok true)))

(define-public (link-identity-to-domain (domain (string-ascii 63)))
  (let ((domain-info (unwrap! (map-get? domains { domain: domain }) err-domain-not-found)))
    (asserts! (is-eq (get owner domain-info) tx-sender) err-unauthorized)
    (set-domain-record domain "identity" (principal-to-string tx-sender) u86400)))

(define-public (set-registration-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set registration-fee new-fee)
    (ok true)))

(define-public (set-renewal-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set renewal-fee new-fee)
    (ok true)))

(define-public (set-grace-period (new-period uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set grace-period new-period)
    (ok true)))

(define-public (set-default-renewal-period (new-period uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set default-renewal-period new-period)
    (ok true)))

(define-public (set-domain-length-limits (min-length uint) (max-length uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (and (> min-length u0) (<= max-length u63)) err-invalid-data)
    (var-set min-domain-length min-length)
    (var-set max-domain-length max-length)
    (ok true)))

(define-read-only (get-domain-info (domain (string-ascii 63)))
  (map-get? domains { domain: domain }))

(define-read-only (get-identity-profile (owner principal))
  (map-get? identity-profiles { owner: owner }))

(define-read-only (get-domain-record (domain (string-ascii 63)) (record-type (string-ascii 10)))
  (map-get? domain-records { domain: domain, record-type: record-type }))

(define-read-only (get-resolver-address (domain (string-ascii 63)))
  (map-get? domain-resolvers { domain: domain }))

(define-read-only (resolve-domain-to-identity (domain (string-ascii 63)))
  (get-domain-record domain "identity"))

(define-read-only (resolve-identity-to-domain (owner principal))
  (match (map-get? identity-profiles { owner: owner })
    profile (get primary-domain profile)
    none))

(define-read-only (get-total-domains)
  (var-get total-domains))

(define-read-only (get-registration-fee)
  (var-get registration-fee))

(define-read-only (get-domain-length-limits)
  { min: (var-get min-domain-length), max: (var-get max-domain-length) })

(define-read-only (get-domain-expiration (domain (string-ascii 63)))
  (match (map-get? domains { domain: domain })
    domain-info (some (get expires-at domain-info))
    none))

(define-read-only (is-domain-expired-query (domain (string-ascii 63)))
  (is-domain-expired domain))

(define-read-only (is-in-grace-period-query (domain (string-ascii 63)))
  (is-in-grace-period domain))

(define-read-only (get-renewal-info)
  { 
    default-period: (var-get default-renewal-period), 
    renewal-fee: (var-get renewal-fee),
    grace-period: (var-get grace-period)
  })

(define-read-only (get-domain-renewal-status (domain (string-ascii 63)))
  (match (map-get? domains { domain: domain })
    domain-info 
      (let ((expires-at (get expires-at domain-info))
            (current-block stacks-block-height)
            (grace-end (+ expires-at (var-get grace-period))))
        (some { 
          expires-at: expires-at,
          is-expired: (> current-block expires-at),
          in-grace-period: (and (> current-block expires-at) (<= current-block grace-end)),
          blocks-until-expiry: (if (> expires-at current-block) (- expires-at current-block) u0),
          blocks-until-grace-end: (if (> grace-end current-block) (- grace-end current-block) u0)
        }))
    none))

(define-private (principal-to-string (addr principal))
  "SP1234567890ABCDEF")
