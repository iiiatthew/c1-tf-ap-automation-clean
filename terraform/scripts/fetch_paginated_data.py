# terraform/scripts/fetch_paginated_data.py
import sys
import json
import os
import urllib.request
import urllib.parse
import urllib.error
import ssl  # For potential certificate verification issues


# Configure logging to stderr
def log_error(message):
    print(f"ERROR: {message}", file=sys.stderr)


def log_info(message):
    print(f"INFO: {message}", file=sys.stderr)


def main():
    input_data = {}
    try:
        input_json = sys.stdin.read()
        if not input_json:
            log_error("No input received from stdin.")
            # Output empty map for Terraform if no input
            print(json.dumps({"combined_list": "[]"}))
            sys.exit(0)
        input_data = json.loads(input_json)
    except json.JSONDecodeError as e:
        log_error(f"Failed to decode JSON input: {e}")
        log_error(f"Received input: {input_json}")
        print(json.dumps({"error": f"Failed to decode JSON input: {e}"}))
        sys.exit(1)
    except Exception as e:
        log_error(f"An unexpected error occurred reading stdin: {e}")
        print(json.dumps({"error": f"An unexpected error occurred reading stdin: {e}"}))
        sys.exit(1)

    api_url_base = input_data.get("api_url_base")
    api_token = input_data.get("api_token")
    page_size = input_data.get("page_size", "100")  # Keep as string for query params

    # Handle potentially empty URL passed by Terraform if prerequisite local is null
    if not api_url_base:
        log_info("Received empty 'api_url_base'. Returning empty list.")
        print(json.dumps({"combined_list": "[]"}))
        sys.exit(0)

    if not api_token:
        log_error("Missing required input field: 'api_token'")
        print(json.dumps({"error": "Missing required input field: 'api_token'"}))
        sys.exit(1)

    # Validate page_size (remains string until used in params)
    try:
        page_size_int = int(page_size)
        if not 10 <= page_size_int <= 100:
            log_info(f"Page size {page_size} outside 10-100 range. Using default 100.")
            page_size = "100"
    except ValueError:
        log_info(f"Invalid page size '{page_size}'. Using default 100.")
        page_size = "100"

    combined_results = []
    next_page_token = None
    page_count = 0
    max_pages = 20  # Safety limit

    # Context to potentially ignore SSL verification if needed, though generally not recommended
    # ssl_context = ssl._create_unverified_context()
    ssl_context = None  # Default: use system certs

    log_info(f"Starting pagination for: {api_url_base} with page_size: {page_size}")

    while page_count < max_pages:
        page_count += 1
        params = {"page_size": page_size}
        if next_page_token:
            params["page_token"] = next_page_token

        # Encode parameters and append to URL
        query_string = urllib.parse.urlencode(params)
        current_url = f"{api_url_base}?{query_string}"

        log_info(f"Fetching page {page_count} with URL: {current_url}")

        try:
            req = urllib.request.Request(current_url)
            req.add_header("Authorization", f"Bearer {api_token}")
            req.add_header("Accept", "application/json")

            with urllib.request.urlopen(
                req, context=ssl_context, timeout=30
            ) as response:
                if response.status < 200 or response.status >= 300:
                    raise urllib.error.HTTPError(
                        current_url,
                        response.status,
                        f"HTTP Status {response.status}",
                        response.headers,
                        response,
                    )

                response_body = response.read().decode("utf-8")
                response_data = json.loads(response_body)

                page_items = response_data.get("list", [])
                if isinstance(page_items, list):
                    combined_results.extend(page_items)
                    log_info(f"Page {page_count}: Found {len(page_items)} items.")
                else:
                    log_info(
                        f"Page {page_count}: 'list' field is not a list or is missing. Response: {response_data}"
                    )

                next_page_token = response_data.get("nextPageToken")

                if not next_page_token:
                    log_info(
                        f"Page {page_count}: No nextPageToken found. Ending pagination."
                    )
                    break  # Exit loop

        except urllib.error.HTTPError as e:
            log_error(f"HTTP Error {e.code}: {e.reason}")
            try:
                error_body = e.read().decode("utf-8")
                log_error(f"Error Body: {error_body}")
                print(
                    json.dumps(
                        {
                            "error": f"HTTP Error {e.code}: {e.reason}. Body: {error_body}"
                        }
                    )
                )
            except:
                print(json.dumps({"error": f"HTTP Error {e.code}: {e.reason}"}))
            sys.exit(1)
        except urllib.error.URLError as e:
            # Catches non-HTTP errors (like connection refused, DNS issues)
            log_error(f"URL Error: {e.reason}")
            print(json.dumps({"error": f"URL Error: {e.reason}"}))
            sys.exit(1)
        except json.JSONDecodeError as e:
            log_error(f"Failed to decode JSON response: {e}")
            log_error(f"Response body: {response_body}")
            print(json.dumps({"error": f"Failed to decode JSON response: {e}"}))
            sys.exit(1)
        except Exception as e:  # Catch any other unexpected errors
            log_error(f"An unexpected error occurred during API call: {e}")
            print(json.dumps({"error": f"An unexpected error occurred: {e}"}))
            sys.exit(1)

    else:  # Loop finished due to max_pages limit
        log_error(
            f"Reached maximum page limit ({max_pages}) before finding the end of results for {api_url_base}."
        )
        # Outputting what we have, but logged the error.

    # Output the combined list as JSON required by data "external"
    output_json = json.dumps({"combined_list": json.dumps(combined_results)})
    print(output_json)
    log_info(f"Finished pagination. Total items fetched: {len(combined_results)}")


if __name__ == "__main__":
    main()
