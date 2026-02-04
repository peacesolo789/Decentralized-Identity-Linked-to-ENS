# 🆔 Decentralized Identity Linked to ENS

> 🚀 A Stacks blockchain smart contract that enables decentralized identity management with ENS-like domain resolution

## 📋 Overview

This project provides a complete decentralized identity solution that allows users to:
- 🏷️ Register and manage custom domains
- 👤 Create comprehensive identity profiles
- 🔗 Link identities to domains for easy resolution
- 📝 Set custom DNS-like records
- 🔄 Transfer domain ownership

## ✨ Features

### 🌐 Domain Management
- Register unique domains with TTL settings
- Transfer domain ownership between users
- Set custom resolvers for domains
- Configure DNS-like records (A, CNAME, TXT, etc.)

### 👥 Identity Profiles
- Create detailed user profiles with social media links
- Set primary domain for identity resolution
- Update profile information anytime
- Link multiple social platforms (GitHub, Twitter, Discord)

### 🔍 Resolution System
- Resolve domains to identity owners
- Resolve identities to their primary domains
- Set custom resolver addresses
- Query domain records by type

## 🛠️ Usage Instructions

### 🔧 Setup
1. Clone this repository
2. Install Clarinet: `npm install -g @hirosystems/clarinet`
3. Run tests: `clarinet test`
4. Deploy locally: `clarinet console`

### 📦 Contract Functions

#### Domain Registration
```clarity
(contract-call? .decentralized-identity-linked-to-ens register-domain "alice" u86400)
```

#### Create Identity Profile
```clarity
(contract-call? .decentralized-identity-linked-to-ens create-identity-profile
  u"Alice Smith"           ; display-name
  "https://avatar.url"     ; avatar
  "alice@example.com"      ; email
  "https://alice.dev"      ; website
  u"Web3 developer"        ; bio
  "alice"                  ; github
  "alicedev"              ; twitter
  "alice#1234")           ; discord
```

#### Link Identity to Domain
```clarity
(contract-call? .decentralized-identity-linked-to-ens link-identity-to-domain "alice")
```

#### Set Primary Domain
```clarity
(contract-call? .decentralized-identity-linked-to-ens set-primary-domain "alice")
```

#### Set Domain Records
```clarity
(contract-call? .decentralized-identity-linked-to-ens set-domain-record 
  "alice"           ; domain
  "A"              ; record-type
  "192.168.1.1"    ; value
  u3600)           ; ttl
```

### 🔍 Query Functions

#### Get Domain Info
```clarity
(contract-call? .decentralized-identity-linked-to-ens get-domain-info "alice")
```

#### Get Identity Profile
```clarity
(contract-call? .decentralized-identity-linked-to-ens get-identity-profile 'SP...)
```

#### Resolve Domain to Identity
```clarity
(contract-call? .decentralized-identity-linked-to-ens resolve-domain-to-identity "alice")
```

#### Resolve Identity to Domain
```clarity
(contract-call? .decentralized-identity-linked-to-ens resolve-identity-to-domain 'SP...)
```

## 🏗️ Contract Architecture

### 📊 Data Maps
- `domains` - Domain registration and ownership data
- `identity-profiles` - User profile information
- `domain-records` - DNS-like records for domains
- `domain-resolvers` - Custom resolver addresses

### 🔐 Access Control
- Domain owners can transfer and manage their domains
- Resolvers can update domain records
- Contract owner can set fees and limits

### ⚙️ Configuration
- Adjustable registration fees
- Configurable domain length limits (3-63 characters)
- TTL settings for records

## 🧪 Testing

Run the test suite:
```bash
clarinet test
```

Check contract syntax:
```bash
clarinet check
```

## 🚀 Deployment

### Local Development
```bash
clarinet console
```

### Testnet Deployment
```bash
clarinet publish --testnet
```

### Mainnet Deployment
```bash
clarinet publish --mainnet
```

## 📄 License

MIT License - see LICENSE file for details

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 🔗 Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarinet Documentation](https://docs.hiro.so/clarinet/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)

---

Built with ❤️ on Stacks blockchain
