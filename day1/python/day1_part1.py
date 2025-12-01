def read_instruction(line: str):
    if line[0] == 'L':
        return -1 * int(line[1:])
    else:
        return int(line[1:])

def read_input(path: str):
    with open(path) as f:
        return [read_instruction(line) for line in f]

def main():
    instructions = read_input('input.txt')
    current_position = 50
    zero_count = 0
    for instruction in instructions:
        current_position += instruction
        current_position = current_position % 100
        if current_position == 0:
            zero_count += 1
    print(zero_count)

if __name__ == '__main__':
    main()
