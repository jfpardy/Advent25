with open("../input.txt") as f:
    total = 0
    for line in f:
        line = line.strip()
        if not line:
            continue

        max_digit = max(line)

        pos = -1
        for i, c in enumerate(line[:-1]):
            if c == max_digit:
                pos = i
                break

        if pos != -1:
            joltage = int(max_digit + max(line[pos + 1:]))
        else:
            second_max = max(line[:-1])
            joltage = int(second_max + max_digit)

        total += joltage

    print(total)
