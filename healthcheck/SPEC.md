# Specification

- `check.py` runs healthchecks for my personal web properties. It accepts arguments to
  target alternate ports, which I will use when testing new infrastructure.

- It fetches a series of domains, using `requests`, and makes assertions about the
  responses. It prints the result of eaach assertion, and summarizes them. If every test
  passes, it exits with status `0`.

## Checks

- All HTTPS responses should contain HTTP HSTS headers.
- All HTTPS responses should have valid certificates.

## Domains and specific checks

- `http://nelhage.com/`
  - Should redirect to `https`

- `http://www.nelhage.com/`  and `https://www.nelhage.com/`
  - Should redirect to the apex domain (nelhage.com), using TLS.

- `https://nelhage.com/`
  - Should return HTTP 200
  - Should return an HTML content type
  - Body should contain the strings: "Nelson Elhage", "nelhage@nelhage.com", "https://blog.nelhage.com"

- `http://livegrep.com`
  - Should redirect to https

- `http://www.livegrep.com` and `https://www.livegrep.com`
  - Should redirect to the apex, using TLS

- `https://livegrep.com`
  - Should return an HTTP 200
  - Should redirect to `/search`

- `https://livegrep.com/search/linux`
  - Should return a 200 status
  - Should contain the string "torvalds/Linux"
