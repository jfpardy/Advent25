def read_instruction(line: str):
    if line[0] == 'L':
        return -1 * int(line[1:])
    else:
        return int(line[1:])

def read_input(path: str):
    with open(path) as f:
        return [read_instruction(line) for line in f]

def count_zeros_passed(position: int, distance: int) -> int:
    if distance > 0:
        return (position + distance) // 100
    else:
        d = abs(distance)
        if position == 0:
            return d // 100
        elif d >= position:
            return (d - position) // 100 + 1
        else:
            return 0

def main():
    current_position = 50
    zero_count = 0
    instructions = read_input('input.txt')
    for instruction in instructions:
        zero_count += count_zeros_passed(current_position, instruction)
        current_position = (current_position + instruction) % 100

    print(zero_count)
if __name__ == '__main__':
    main()
