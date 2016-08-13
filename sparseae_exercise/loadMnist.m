function patches = loadMnist()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
images = loadMNISTImages('../data/train-images.idx3-ubyte');
patches = images(:, 1:10000);

end

