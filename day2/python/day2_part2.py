def find_repeated_in_range(low, high):
    results = set()
    max_digits = len(str(high))

    for d in range(1, max_digits + 1):
        for k in range(2, max_digits // d + 1):
            total_digits = d * k
            multiplier = (10**total_digits - 1) // (10**d - 1)

            min_base = 10**(d-1) if d > 1 else 1
            max_base = 10**d - 1

            min_from_range = (low + multiplier - 1) // multiplier
            max_from_range = high // multiplier

            actual_min = max(min_base, min_from_range)
            actual_max = min(max_base, max_from_range)

            for base in range(actual_min, actual_max + 1):
                results.add(base * multiplier)

    return results


with open("input.txt") as f:
    line = f.read().strip()

all_invalid = set()
for part in line.split(","):
    low, high = map(int, part.split("-"))
    all_invalid.update(find_repeated_in_range(low, high))

print(sum(all_invalid))
