# Audit GitHub Repo

## Introduction

This is a small utility focused on checking that e-mail addresses being used as commit signatures in a GitHub organisation are from a designated set of domains.

## TL;DR;

```bash
$ cp config-example config
$ ./audit.sh config
```

## Configuration

| Parameter                  | Description                                     | Example                                                      |
| -------------------------- | ----------------------------------------------- | ------------------------------------------------------------ |
| `BEARER_TOKEN`         | GitHub bearer token used for authenticating against the GitHub API                      | `abc123`                                        |
| `GITHUB_ORG`                | GitHub Organisation to be audited                            | `MYORG`                                                     |
| `DATE_FILTER`         | This is a "date diff" passed to `date -d`. Used to determine the scope of the audit.                               | `"14 days ago"`                                               |
| `APPROVAL_FILTER`        | This is an e-mail filter passed to `egrep -v`. Used to determine the scope of the audit.                    | `"@myorg.com$|@users.noreply.github.com"`                                                         |
| `REPO_FILTER`        | *[OPTIONAL]* This is a repo filter passed to `egrep -v`. Used to determine the scope of the audit.                    | `archived`                                                         |
| `SKIP_GET`        | *[OPTIONAL]* This is a boolean value which enables skipping the repo retrievals. This can be used to quickly test variations of `DATE_FILTER` and `APPROVAL_FILTER`.                     | `True`                                                         |
| `REPO_LIST`        | *[OPTIONAL]* This is a path to a text file containing repo names. This can be used to alter the scope of the audit to a subset of the repos in an organisation.                     | `my-repos.txt`                                                         |
