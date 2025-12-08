with open("../input.txt") as f:
    grid = [list(line.rstrip('\n')) for line in f if line.strip()]

rows = len(grid)
cols = len(grid[0]) if rows > 0 else 0

directions = [(-1, -1), (-1, 0), (-1, 1),
              (0, -1),          (0, 1),
              (1, -1),  (1, 0), (1, 1)]

def count_neighbors(r, c):
    count = 0
    for dr, dc in directions:
        nr, nc = r + dr, c + dc
        if 0 <= nr < rows and 0 <= nc < cols and grid[nr][nc] == '@':
            count += 1
    return count

def find_accessible():
    accessible = []
    for r in range(rows):
        for c in range(cols):
            if grid[r][c] == '@' and count_neighbors(r, c) < 4:
                accessible.append((r, c))
    return accessible

total_removed = 0

while True:
    accessible = find_accessible()
    if not accessible:
        break
    for r, c in accessible:
        grid[r][c] = '.'
    total_removed += len(accessible)

print(total_removed)
