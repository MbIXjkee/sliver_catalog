# Package Release Guide

This document describes the steps required to prepare, validate, and publish a new release of the package.

## 1. Determine the Next Version

Open the CHANGELOG.md file. Review the Unreleased section and based on the changes and following Semantic Versioning (SemVer) guidelines choose the next version number.

## 2. Create a Release Preparation Branch

```bash
# Fetch latest and create a branch for this release
git fetch origin
git checkout -b prepare_release_<VERSION>
```

## 3. Update version related places

### Set the package version

Locate the `version:` field in `pubspec.yaml` and update it:
```yaml
version: <VERSION>
```

### Update changelog
Move unreleased changes in `CHANGELOG.md` to:
```markdown
## <VERSION>
```

Add a new empty Unreleased section at the top:
```markdown
## Unreleased
```

### Update demo link in `README.md`:
```code
<a href="https://mbixjkee.github.io/sliver_catalog/release_<VERSION>/">...</a>
```

## 4. Push & Validate

```bash
git add pubspec.yaml CHANGELOG.md README.md
git commit -m "Chore: Prepare release <VERSION>"
git push --set-upstream origin prepare_release_<VERSION>
```

## 5. Merge Pull Request

In GitHub:

Open the PR for prepare_release_<VERSION>.

Confirm that all checks have passed.

Merge the PR.

## 5. Tag the Release

```bash
git fetch origin
git checkout main
git pull origin main
git tag release_<VERSION>
git push origin release_<VERSION>
```

## 6. Verify Release Workflow

After tagging, confirm that the GitHub action with release workflow has been triggered.

Check the workflow successfully completed.

Verify that the package is available on pub.dev.