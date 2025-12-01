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
		pos = (pos + instr) % 100;
		if (pos < 0)
			pos += 100;
		if (pos == 0)
			cnt++;
	}

	fclose(f);
	printf("%d\n", cnt);
	return 0;
}
