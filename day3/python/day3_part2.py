with open("../input.txt") as f:
    total = 0
    for line in f:
        line = line.strip()
        if not line:
            continue

        result = ""
        remaining = line
        for i in range(12):
            digits_still_needed = 12 - i
            searchable = remaining[:len(remaining) - digits_still_needed + 1]
            max_digit = max(searchable)
            pos = searchable.index(max_digit)
            result += max_digit
            remaining = remaining[pos + 1:]

        total += int(result)

    print(total)
