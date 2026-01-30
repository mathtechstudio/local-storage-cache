# Release Process Guide

Panduan lengkap untuk membuat release di repository ini.

## 📋 Overview

Repository ini menggunakan **Release Drafter** untuk otomatis membuat draft release dan **GitHub Actions** untuk publish release dengan tags.

## 🔄 Workflow Release

### 1. Development & PR

Ketika membuat PR, tambahkan label yang sesuai:

- `breaking` / `breaking-change` → Major version bump (v3.0.0)
- `feature` / `feat` / `enhancement` → Minor version bump (v2.1.0)
- `fix` / `bug` → Patch version bump (v2.0.1)
- `docs` / `chore` / `refactor` → Patch version bump (v2.0.1)

**Contoh**:

```bash
# PR dengan label "fix" akan menghasilkan v2.0.1
# PR dengan label "feature" akan menghasilkan v2.1.0
# PR dengan label "breaking" akan menghasilkan v3.0.0
```

### 2. Merge ke Main

Setelah PR di-merge ke `main`:

1. **Release Drafter otomatis membuat/update draft release**
2. Buka: `https://github.com/YOUR_USERNAME/local-storage-cache/releases`
3. Anda akan melihat draft release dengan:
   - ✅ Title: `v2.0.1` (otomatis)
   - ✅ Description: List semua PR yang di-merge (otomatis)
   - ✅ Categorized by labels (otomatis)

### 3. Publish Release (2 Cara)

#### Cara 1: Manual via GitHub UI (Recommended untuk kontrol penuh)

1. Buka draft release di GitHub
2. Review title, description, dan changes
3. Edit jika perlu (tambahkan catatan khusus, breaking changes, dll)
4. Klik **"Publish release"**
5. GitHub otomatis membuat tag dan trigger workflow release

#### Cara 2: Via Git Command Line (Untuk advanced users)

```bash
# 1. Pastikan di main branch dan up to date
git checkout main
git pull origin main

# 2. Buat tag dengan format v*.*.* 
git tag -a v2.0.1 -m "Release v2.0.1"

# 3. Push tag ke GitHub
git push origin v2.0.1

# 4. GitHub Actions otomatis:
#    - Run tests
#    - Run analysis
#    - Generate changelog
#    - Create release
```

## 📝 Format Commit Messages

Gunakan conventional commits untuk changelog yang lebih baik:

```bash
feat(query): add support for LEFT JOIN operations
fix(cache): resolve memory leak in LFU eviction
docs(readme): update installation instructions
perf(storage): optimize batch insert performance
refactor(core): simplify query builder logic
test(engine): add tests for transaction rollback
chore(deps): update dependencies
ci(workflow): fix Windows PATH configuration
```

## 🏷️ Version Numbering (Semantic Versioning)

Format: `MAJOR.MINOR.PATCH` (contoh: `v2.0.1`)

- **MAJOR** (v3.0.0): Breaking changes yang tidak backward compatible
- **MINOR** (v2.1.0): New features yang backward compatible
- **PATCH** (v2.0.1): Bug fixes dan improvements

## 📦 Contoh Release Description (Otomatis)

```markdown
## Changes

### 🚀 New Features
- Add support for LEFT JOIN operations (#123)
- Implement query caching mechanism (#124)

### 🐛 Bug Fixes
- Fix memory leak in LFU eviction (#125)
- Resolve cache invalidation issue (#126)

### 📚 Documentation
- Update README with new examples (#127)

### 🔧 Maintenance
- Update dependencies (#128)
- Fix CI workflow for Windows (#129)

## Installation

Add this to your package's `pubspec.yaml` file:

\`\`\`yaml
dependencies:
  local_storage_cache: ^2.0.1
\`\`\`

## Contributors

@username1, @username2
```

## 🔍 Checklist Sebelum Release

- [ ] All CI workflows passing (code-quality, code-integration)
- [ ] All tests passing (380+ tests)
- [ ] No analyzer warnings
- [ ] CHANGELOG.md updated (optional, Release Drafter handles this)
- [ ] Version number di pubspec.yaml sudah benar
- [ ] Breaking changes documented (jika ada)
- [ ] Migration guide provided (jika ada breaking changes)

## 🚀 Post-Release

Setelah release published:

1. **Verify release**: Check GitHub releases page
2. **Update documentation**: Jika ada perubahan API
3. **Announce**: Inform users via channels (Discord, Twitter, dll)
4. **Monitor**: Watch for issues or bug reports

## 🛠️ Troubleshooting

### Draft release tidak muncul?

- Pastikan PR sudah di-merge ke `main`
- Check workflow runs di Actions tab
- Pastikan release-drafter.yml config benar

### Version number salah?

- Edit draft release di GitHub UI
- Ubah title dan tag sebelum publish
- Atau delete draft dan buat manual

### Ingin skip release drafter?

Buat release manual:

1. Go to Releases → "Draft a new release"
2. Choose tag: Create new tag `v2.0.1`
3. Target: `main`
4. Write description manually
5. Publish

## 📚 Resources

- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Release Drafter](https://github.com/release-drafter/release-drafter)
- [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github)
