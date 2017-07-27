function [best, score] = spline_grad_search(function_to_optimise,lower_bound_upper_bound,starting_point,grad_search_params)
% [best, score] = spline_grad_search(function_to_optimise,lower_bound_upper_bound,starting_point,grad_search_params)
% simple Powell like line method for based optimsation.
% taken in large part from Numerical Methods in C, but tries to take
% advantage of parallel speed of cost function by searching multiple steps
% at once in the linesearch.
% grad_search_params : structure of parameters for optimisation:
%   max_iterations  - maximum number of full linesearches over all
%                     dimensions (default 50)
%   step_num        - number of steps to take either side of the current
%                     point when making the line search (default 5)
%   jump            - size of the initial parameter jump (i.e. the max and
%                     min of the range over which the first search looks).
%                     (default 4)
%   max_lin_iter    - number of linear jumps to make in 1 dimension before
%                     concluding there is no improvement to be had.
%                     (default 5)
%   thresh          - realtive score change threshold at which to break
%                     optimisation. (default 1e-2)

default_params = struct('max_iterations',50,...
                        'step_num',5,...
                        'jump',4,...
                        'max_lin_iter',5,...
                        'thresh',1e-2);
if nargin<3 || isempty(grad_search_params)
    grad_search_params = default_params;
else
    grad_search_params = parse_struct(grad_search_params,default_params);
end

max_iterations = grad_search_params.max_iterations;
step_num = grad_search_params.step_num;
jump = grad_search_params.jump;
max_lin_iter = grad_search_params.max_lin_iter;
thresh = grad_search_params.thresh;

dims = length(starting_point);
vs = dims+1;
bigLB = repmat(lower_bound_upper_bound(:,1)',[2*step_num,1]);
bigUB = repmat(lower_bound_upper_bound(:,2)',[2*step_num,1]);

vectors = eye(dims);
vectors = cat(1,ones(1,dims),vectors);

old_score = function_to_optimise(starting_point);

new_scores = old_score*ones(vs,1);

current_point = starting_point;

multiD_iteration = 0;

new_jump = jump;
while multiD_iteration<max_iterations
iter_point = current_point;
% search 
current_best = old_score;
for vi = 1:vs
    iter_jump = new_jump;
    iter = 0;
    iter_score = zeros(step_num,1);
    steps = linspace(-iter_jump,iter_jump,2*step_num)';
    while iter<max_lin_iter
        iter = iter+1;
        new_points = repmat(iter_point,[size(steps,1),1]) + kron(vectors(vi,:),steps);
        
        % don't use points outside the bounds
        to_use = ~(any((new_points<bigLB) | (new_points>bigUB),2));
        if any(to_use)
            iter_score(to_use) = function_to_optimise(new_points(to_use,:));
        end
        iter_score(~to_use) = Inf;
        [m,I] = min(iter_score);
        
        if m<current_best
            % store new score
            new_scores(vi) = m;
            current_best = m;
            iter_point = new_points(I,:);
            break
        else
            % if none of the points tried were better than the current
            % point set steps to inner region and try again.
            steps = linspace(-steps(step_num+1),steps(step_num+1),2*step_num)';
        end
    end
    
    
end

if multiD_iteration==max_iterations
    fprintf('\n\noptimiser maxed out!!\n\n');
end

% replace vector 1 (not attached to a particular dimension) with the total
% change on this iteration.
improvement = diff([old_score;new_scores]);
[best_improvement] = min(improvement);
% if no improvement or only improvement below threshold, break the loop
if all(current_point==iter_point) || (-best_improvement/abs(new_scores(end)))<thresh
    break
end

new_vec = iter_point - current_point;
% if the total change was small than 0.5* jump, reduce jump to 2*change on
% this iteration.
new_jump = min(jump,2*max(abs(new_vec)));
new_vec = new_vec/max(new_vec);
vectors(1,:) = new_vec;
current_point = iter_point;
old_score = new_scores(end);
new_scores(:) = old_score;


multiD_iteration = multiD_iteration+1;
end

best = iter_point;
score = new_scores(end);

end
