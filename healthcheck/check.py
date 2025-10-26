from urllib.parse import urlparse, urlunparse

import requests


class TestResults:
    """Track test results."""

    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.errors = []

    def record_pass(self, message: str):
        """Record a passing test."""
        self.passed += 1
        print(f"✓ {message}")

    def record_fail(self, message: str, detail: str = ""):
        """Record a failing test."""
        self.failed += 1
        error_msg = f"✗ {message}"
        if detail:
            error_msg += f"\n  {detail}"
        print(error_msg)
        self.errors.append(message)

    def summary(self):
        """Print summary and return exit code."""
        total = self.passed + self.failed
        print(f"\n{self.passed}/{total} tests passed")
        return 0 if self.failed == 0 else 1


def substitute_port(url: str, http_port: int, tls_port: int) -> str:
    """Substitute custom ports into a URL."""
    parsed = urlparse(url)

    # Determine the new port based on scheme
    if parsed.scheme == "http":
        new_port = http_port if http_port != 80 else None
    elif parsed.scheme == "https":
        new_port = tls_port if tls_port != 443 else None
    else:
        new_port = parsed.port

    # Reconstruct netloc with new port
    if new_port:
        hostname = parsed.hostname or ""
        netloc = f"{hostname}:{new_port}"
    else:
        netloc = parsed.hostname or ""

    return urlunparse((
        parsed.scheme,
        netloc,
        parsed.path,
        parsed.params,
        parsed.query,
        parsed.fragment
    ))


def check_hsts(response: requests.Response, results: TestResults, url: str):
    """Check if response has HSTS header."""
    if "strict-transport-security" in response.headers:
        results.record_pass(f"{url} has HSTS header")
    else:
        results.record_fail(f"{url} missing HSTS header")


def check_cert_valid(url: str, results: TestResults):
    """Check if HTTPS certificate is valid."""
    try:
        requests.get(url, timeout=10)
        results.record_pass(f"{url} has valid certificate")
    except requests.exceptions.SSLError as e:
        results.record_fail(f"{url} has invalid certificate", str(e))


def check_redirect(url: str, expected_target: str, results: TestResults, http_port: int, tls_port: int):
    """Check if URL redirects to expected target."""
    try:
        response = requests.get(url, allow_redirects=False, timeout=10)

        if response.status_code not in (301, 302, 303, 307, 308):
            results.record_fail(
                f"{url} should redirect to {expected_target}",
                f"Got status {response.status_code} instead of 30x"
            )
            return

        location = response.headers.get("location", "")

        # Normalize the location for comparison
        if location.startswith("/"):
            # Relative redirect - make it absolute for comparison
            parsed_url = urlparse(url)
            location = f"{parsed_url.scheme}://{parsed_url.netloc}{location}"

        # Apply port substitution to expected target for comparison
        expected_with_ports = substitute_port(expected_target, http_port, tls_port)

        if location == expected_with_ports:
            results.record_pass(f"{url} redirects to {expected_target}")
        else:
            results.record_fail(
                f"{url} should redirect to {expected_target}",
                f"Got redirect to {location}"
            )
    except Exception as e:
        results.record_fail(f"{url} redirect check failed", str(e))


def check_status(url: str, expected_status: int, results: TestResults):
    """Check if URL returns expected status code."""
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == expected_status:
            results.record_pass(f"{url} returns {expected_status}")
        else:
            results.record_fail(
                f"{url} should return {expected_status}",
                f"Got status {response.status_code}"
            )
        return response
    except Exception as e:
        results.record_fail(f"{url} status check failed", str(e))
        return None


def check_content_type(response: requests.Response, expected_type: str, results: TestResults, url: str):
    """Check if response has expected content type."""
    content_type = response.headers.get("content-type", "")
    if expected_type.lower() in content_type.lower():
        results.record_pass(f"{url} has {expected_type} content type")
    else:
        results.record_fail(
            f"{url} should have {expected_type} content type",
            f"Got content-type: {content_type}"
        )


def check_body_contains(response: requests.Response, strings: list[str], results: TestResults, url: str):
    """Check if response body contains expected strings."""
    body = response.text
    for string in strings:
        if string in body:
            results.record_pass(f"{url} contains '{string}'")
        else:
            results.record_fail(f"{url} should contain '{string}'")


def main(
    *,
    http_port: int = 80,
    tls_port: int = 443,
):
    results = TestResults()

    # nelhage.com checks
    # http://nelhage.com/ should redirect to https
    url = substitute_port("http://nelhage.com/", http_port, tls_port)
    check_redirect(url, "https://nelhage.com/", results, http_port, tls_port)

    # http://www.nelhage.com/ should redirect to https://nelhage.com/
    url = substitute_port("http://www.nelhage.com/", http_port, tls_port)
    check_redirect(url, "https://nelhage.com/", results, http_port, tls_port)

    # https://www.nelhage.com/ should redirect to https://nelhage.com/
    url = substitute_port("https://www.nelhage.com/", http_port, tls_port)
    check_redirect(url, "https://nelhage.com/", results, http_port, tls_port)

    # https://nelhage.com/ checks
    url = substitute_port("https://nelhage.com/", http_port, tls_port)

    # Certificate should be valid
    check_cert_valid(url, results)

    # Should return 200 with HTML content containing specific strings
    response = check_status(url, 200, results)
    if response:
        check_hsts(response, results, url)
        check_content_type(response, "html", results, url)
        check_body_contains(
            response,
            ["Nelson Elhage", "nelhage@nelhage.com", "https://blog.nelhage.com"],
            results,
            url
        )

    # livegrep.com checks
    # http://livegrep.com should redirect to https
    url = substitute_port("http://livegrep.com", http_port, tls_port)
    check_redirect(url, "https://livegrep.com/", results, http_port, tls_port)

    # http://www.livegrep.com should redirect to https://livegrep.com
    url = substitute_port("http://www.livegrep.com", http_port, tls_port)
    check_redirect(url, "https://livegrep.com/", results, http_port, tls_port)

    # https://www.livegrep.com should redirect to https://livegrep.com
    url = substitute_port("https://www.livegrep.com", http_port, tls_port)
    check_redirect(url, "https://livegrep.com/", results, http_port, tls_port)

    # https://livegrep.com checks
    url = substitute_port("https://livegrep.com/", http_port, tls_port)

    # Certificate should be valid
    check_cert_valid(url, results)

    # Should redirect to /search
    check_redirect(url, "https://livegrep.com/search", results, http_port, tls_port)

    # https://livegrep.com/search/linux checks
    url = substitute_port("https://livegrep.com/search/linux", http_port, tls_port)

    response = check_status(url, 200, results)
    if response:
        check_hsts(response, results, url)
        check_body_contains(response, ["torvalds/linux"], results, url)

    exit(results.summary())


if __name__ == "__main__":
    import cyclopts

    cyclopts.run(main)
