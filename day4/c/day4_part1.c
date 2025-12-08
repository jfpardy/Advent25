#include <stdio.h>
#include <string.h>

#define MAX_ROWS 150
#define MAX_COLS 150

static char grid[MAX_ROWS][MAX_COLS];
static int rows, cols;

/* 8 directions */
static int dr[] = {-1, -1, -1,  0, 0,  1, 1, 1};
static int dc[] = {-1,  0,  1, -1, 1, -1, 0, 1};

static int
count_neighbors(r, c)
int r, c;
{
	int count, i, nr, nc;

	count = 0;
	for (i = 0; i < 8; i++) {
		nr = r + dr[i];
		nc = c + dc[i];
		if (nr >= 0 && nr < rows && nc >= 0 && nc < cols)
			if (grid[nr][nc] == '@')
				count++;
	}
	return count;
}

static int
is_accessible(r, c)
int r, c;
{
	if (grid[r][c] != '@')
		return 0;
	return count_neighbors(r, c) < 4;
}

int
main()
{
	FILE *f;
	char line[256];
	int len, r, c, count;

	f = fopen("../input.txt", "r");
	if (f == NULL) {
		perror("../input.txt");
		return 1;
	}

	rows = 0;
	while (fgets(line, sizeof(line), f) != NULL) {
		len = strlen(line);
		if (len > 0 && line[len - 1] == '\n')
			len--;
		if (len == 0)
			continue;
		memcpy(grid[rows], line, len);
		cols = len;
		rows++;
	}
	fclose(f);

	count = 0;
	for (r = 0; r < rows; r++)
		for (c = 0; c < cols; c++)
			if (is_accessible(r, c))
				count++;

	printf("Part 1: %d\n", count);
	return 0;
}
