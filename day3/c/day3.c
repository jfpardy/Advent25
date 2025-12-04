#include <stdio.h>
#include <string.h>

static long long
pick_digits(line, len, n)
char *line;
int len, n;
{
	long long result;
	int start, end, i, j, max_pos;
	char max_ch;

	result = 0;
	start = 0;

	for (i = 0; i < n; i++) {
		end = len - (n - i);
		max_ch = line[start];
		max_pos = start;
		for (j = start; j <= end; j++) {
			if (line[j] > max_ch) {
				max_ch = line[j];
				max_pos = j;
			}
		}
		result = result * 10 + (max_ch - '0');
		start = max_pos + 1;
	}
	return result;
}

int
main()
{
	FILE *f;
	char line[256];
	int len;
	long long part1, part2;

	f = fopen("../input.txt", "r");
	if (f == NULL) {
		perror("../input.txt");
		return 1;
	}

	part1 = 0;
	part2 = 0;

	while (fgets(line, sizeof(line), f) != NULL) {
		len = strlen(line);
		if (len > 0 && line[len - 1] == '\n')
			len--;
		if (len == 0)
			continue;

		part1 += pick_digits(line, len, 2);
		part2 += pick_digits(line, len, 12);
	}

	fclose(f);
	printf("Part 1: %lld\n", part1);
	printf("Part 2: %lld\n", part2);
	return 0;
}
