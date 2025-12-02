#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define MAX_INVALID 100000

static double invalid_ids[MAX_INVALID];
static int invalid_count = 0;

static int
num_digits(n)
    double n;
{
    int count = 0;
    if (n < 1) return 1;
    while (n >= 1) {
        n /= 10;
        count++;
    }
    return count;
}

static double
power10(exp)
    int exp;
{
    double result = 1;
    int i;
    for (i = 0; i < exp; i++)
        result *= 10;
    return result;
}

static double
ceil_div(a, b)
    double a, b;
{
    double q = floor(a / b);
    if (q * b < a) q += 1;
    return q;
}

static void
add_if_unique(val)
    double val;
{
    int i;
    for (i = 0; i < invalid_count; i++) {
        if (invalid_ids[i] == val)
            return;
    }
    if (invalid_count < MAX_INVALID)
        invalid_ids[invalid_count++] = val;
}

static double
part1_range(low, high)
    double low, high;
{
    double total = 0;
    double multiplier, min_doubled, min_base, max_base, base_min, base_max;
    double count, base_sum;
    int k;

    for (k = 1; ; k++) {
        multiplier = power10(k) + 1;
        min_doubled = (k > 1 ? power10(k - 1) : 1) * multiplier;

        if (min_doubled > high)
            break;

        min_base = ceil_div(low, multiplier);
        max_base = floor(high / multiplier);

        base_min = k > 1 ? power10(k - 1) : 1;
        base_max = power10(k) - 1;

        if (min_base < base_min) min_base = base_min;
        if (max_base > base_max) max_base = base_max;

        if (min_base <= max_base) {
            count = max_base - min_base + 1;
            base_sum = (min_base + max_base) * count / 2;
            total += base_sum * multiplier;
        }
    }
    return total;
}

static void
part2_range(low, high)
    double low, high;
{
    int max_digits, d, k, total_digits;
    double multiplier, min_base, max_base, base_min, base_max, base, val;

    max_digits = num_digits(high);

    for (d = 1; d <= max_digits; d++) {
        for (k = 2; k <= max_digits / d; k++) {
            total_digits = d * k;
            multiplier = (power10(total_digits) - 1) / (power10(d) - 1);

            base_min = d > 1 ? power10(d - 1) : 1;
            base_max = power10(d) - 1;

            min_base = ceil_div(low, multiplier);
            max_base = floor(high / multiplier);

            if (min_base < base_min) min_base = base_min;
            if (max_base > base_max) max_base = base_max;

            for (base = min_base; base <= max_base; base += 1) {
                val = base * multiplier;
                add_if_unique(val);
            }
        }
    }
}

int
main()
{
    FILE *fp;
    char buf[8192];
    char *p, *comma, *dash;
    double low, high;
    double part1_total = 0;
    double part2_total = 0;
    int i;

    fp = fopen("input.txt", "r");
    if (!fp) {
        fprintf(stderr, "Cannot open input.txt\n");
        return 1;
    }

    if (!fgets(buf, sizeof(buf), fp)) {
        fclose(fp);
        return 1;
    }
    fclose(fp);

    p = buf;
    while (*p && *p != '\n') {
        comma = strchr(p, ',');
        dash = strchr(p, '-');

        if (!dash) break;

        low = atof(p);
        high = atof(dash + 1);

        part1_total += part1_range(low, high);
        part2_range(low, high);

        if (comma)
            p = comma + 1;
        else
            break;
    }

    for (i = 0; i < invalid_count; i++)
        part2_total += invalid_ids[i];

    printf("Part 1: %.0f\n", part1_total);
    printf("Part 2: %.0f\n", part2_total);

    return 0;
}
