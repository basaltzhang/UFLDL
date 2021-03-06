function [ cost, grad ] = stackedAECost(theta, inputSize, hiddenSize, ...
                                              numClasses, netconfig, ...
                                              lambda, data, labels)
                                         
% stackedAECost: Takes a trained softmaxTheta and a training data set with labels,
% and returns cost and gradient using a stacked autoencoder model. Used for
% finetuning.
                                         
% theta: trained weights from the autoencoder
% visibleSize: the number of input units
% hiddenSize:  the number of hidden units *at the 2nd layer*
% numClasses:  the number of categories
% netconfig:   the network configuration of the stack
% lambda:      the weight regularization penalty
% data: Our matrix containing the training data as columns.  So, data(:,i) is the i-th training example. 
% labels: A vector containing labels, where labels(i) is the label for the
% i-th training example


%% Unroll softmaxTheta parameter

% We first extract the part which compute the softmax gradient
softmaxTheta = reshape(theta(1:hiddenSize*numClasses), numClasses, hiddenSize);

% Extract out the "stack"
stack = params2stack(theta(hiddenSize*numClasses+1:end), netconfig);

% You will need to compute the following gradients
softmaxThetaGrad = zeros(size(softmaxTheta));
stackgrad = cell(size(stack));
for d = 1:numel(stack)
    stackgrad{d}.w = zeros(size(stack{d}.w));
    stackgrad{d}.b = zeros(size(stack{d}.b));
end

cost = 0; % You need to compute this

% You might find these variables useful
M = size(data, 2);
groundTruth = full(sparse(labels, 1:M, 1));


%% --------------------------- YOUR CODE HERE -----------------------------
%  Instructions: Compute the cost function and gradient vector for 
%                the stacked autoencoder.
%
%                You are given a stack variable which is a cell-array of
%                the weights and biases for every layer. In particular, you
%                can refer to the weights of Layer d, using stack{d}.w and
%                the biases using stack{d}.b . To get the total number of
%                layers, you can use numel(stack).
%
%                The last layer of the network is connected to the softmax
%                classification layer, softmaxTheta.
%
%                You should compute the gradients for the softmaxTheta,
%                storing that in softmaxThetaGrad. Similarly, you should
%                compute the gradients for each layer in the stack, storing
%                the gradients in stackgrad{d}.w and stackgrad{d}.b
%                Note that the size of the matrices in stackgrad should
%                match exactly that of the size of the matrices in stack.
%
depth = numel(stack);
z = cell(depth+1,1);
a = cell(depth+1, 1);
a{1} = data;
for i = 1 : size(stack, 1)
    z{i + 1} = stack{i}.w * a{i} + repmat(stack{i}.b, 1, size(a{i}, 2));
    a{i + 1} = sigmoid(z{i + 1});
end

M = softmaxTheta * a{depth+1};
M = bsxfun(@minus, M, max(M, [], 1));
M = exp(M);
p = bsxfun(@rdivide, M, sum(M));

cost = - groundTruth(:)' * log(p(:)) / numClasses + lambda * sum(softmaxTheta(:) .^ 2) / 2;

diff = groundTruth - p;
softmaxThetaGrad = - (diff * a{depth+1}') ./ numClasses + lambda * softmaxTheta;

delta = - softmaxTheta' * (groundTruth - p) .* a{depth+1} .* (1 - a{depth+1});

for i = size(stack, 1) : - 1 : 1
    stackgrad{i}.w = delta * a{i}' ./ numClasses;
    stackgrad{i}.b = sum(delta, 2) / numClasses;
    if i ~= 1
        delta = (stack{i}.w' * delta) .* a{i} .* (1 - a{i});
    end
end


% -------------------------------------------------------------------------

%% Roll gradient vector
grad = [softmaxThetaGrad(:) ; stack2params(stackgrad)];

end


% You might find this useful
function sigm = sigmoid(x)
    sigm = 1 ./ (1 + exp(-x));
end
