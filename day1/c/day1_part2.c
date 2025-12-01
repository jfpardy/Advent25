#include <stdio.h>
#include <stdlib.h>

int
read_instruction(s)
char *s;
{
	if (s[0] == 'L')
		return -1 * atoi(s + 1);
	else
		return atoi(s + 1);
}

int
count_zeros(pos, dist)
int pos, dist;
{
	int d;

	if (dist > 0)
		return (pos + dist) / 100;
	d = -dist;
	if (pos == 0)
		return d / 100;
	if (d >= pos)
		return (d - pos) / 100 + 1;
	return 0;
}

int
main()
{
	FILE *f;
	char line[256];
	int pos, cnt, instr;

	f = fopen("input.txt", "r");
	if (f == NULL) {
		perror("input.txt");
		return 1;
	}

	pos = 50;
	cnt = 0;
	while (fgets(line, sizeof(line), f) != NULL) {
		instr = read_instruction(line);
		cnt += count_zeros(pos, instr);
		pos = (pos + instr) % 100;
		if (pos < 0)
			pos += 100;
	}

	fclose(f);
	printf("%d\n", cnt);
	return 0;
}
