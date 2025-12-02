def sum_doubled_in_range(low, high):
    total = 0
    k = 1

    while True:
        multiplier = 10**k + 1
        min_doubled = (10**(k-1) if k > 1 else 1) * multiplier

        if min_doubled > high:
            break

        min_base = (low + multiplier - 1) // multiplier
        max_base = high // multiplier

        min_base = max(min_base, 10**(k-1)) if k > 1 else max(min_base, 1)
        max_base = min(max_base, 10**k - 1)

        if min_base <= max_base:
            count = max_base - min_base + 1
            base_sum = (min_base + max_base) * count // 2
            total += base_sum * multiplier

        k += 1

    return total


with open("input.txt") as f:
    line = f.read().strip()

total = 0
for part in line.split(","):
    low, high = map(int, part.split("-"))
    total += sum_doubled_in_range(low, high)

print(total)
