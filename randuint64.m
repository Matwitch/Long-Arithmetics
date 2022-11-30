function r = randuint64(dim1, dim2)
    arr = randi([0, intmax('uint32')], dim1, dim2, 'uint32');
    r = arrayfun(@(x) typecast([x randi([0, intmax('uint32')])], 'uint64'), arr);
end