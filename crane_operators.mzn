%includes
include "regular.mzn";

% global variables
int: number_of_cranes;
int: max_number_of_operators;
int: total_hours;

set of int: Cranes = 1..number_of_cranes;
set of int: Operators = 1..max_number_of_operators;
set of int: Hours = 1..total_hours;

int: required_resting_hours = 12;
int: max_hours_per_shift = 12;
int: min_hours_per_shift = 4;
int: max_total_hours;

% create a deterministic finite automaton defining the possible states and transitions of an operator: idle (1), operating (2), standby (3)
int: S = 3;
set of int: shifts = 1..S;
array[shifts] of string: shift_name = ["i", "o", "s"];
int: Q = required_resting_hours + max_hours_per_shift; 
set of int: states = 1..Q;
int: q0 = 1;

array[states, shifts] of int: t =
[|  1, 2, 0
 |  0, 3, 3
 |  0, 4, 4
 |  0, 5, 5
 | 14, 0, 6
 | 14, 7, 7
 | 14, 8, 8
 | 14, 9, 9
 | 14, 10, 10
 | 14, 0, 11
 | 14, 12, 12
 | 14, 13, 13
 | 14, 0, 0
 | 15, 0, 0
 | 16, 0, 0
 | 17, 0, 0
 | 18, 0, 0
 | 19, 0, 0
 | 20, 0, 0
 | 21, 0, 0
 | 22, 0, 0
 | 23, 0, 0
 | 24, 0, 0
 |  1, 0, 0
|];

% crane schedule: is crane i operating at time j?
array[Cranes, Hours] of int: crane_schedule;

% decision variable assignment: is operator i assigned at time k?
array[Operators, Hours] of var shifts: assignment;

% constraint: all working cranes must have operators assigned
constraint forall (h in Hours)
           ( sum (c in Cranes) (bool2int(crane_schedule[c, h]==1)) == sum (o in Operators) (bool2int(assignment[o, h]==2)) );

% constraint: operators cannot work more than max_total_hours
constraint forall (o in Operators) 
           ( sum (h in Hours) (bool2int(assignment[o, h]==2)) <= max_total_hours );

% constraint: operators must follow the rooster constraints (cannot work more than 12 hours, must be assigned at least 4 and must rest 12 hours before returning)
constraint forall (o in Operators) (regular([assignment[o, h] | h in Hours], Q, S, t, q0, states));

% minimize number of required operators
var int: operators_required = sum (o in Operators) 
                             ( max (h in Hours) (bool2int(assignment[o, h]==2)) );

solve minimize operators_required;

% output: print operators required and assignment matrix
output [ "\n" ++ "Operators required: " ++ show(operators_required) ++ "\n\n" ] ++ 
       ["hour"] ++ ["\t"] ++ [ show(h) ++ "\t" | h in Hours] ++
       ["\n"] ++
       [ if h == 1 then "\n" ++ "crane " ++ show(c) ++ "\t" else "" endif ++ show(crane_schedule[c, h]) ++ "\t" | c in Cranes, h in Hours ] ++
       ["\n"] ++   
       [ if h == 1 then "\n" ++ "op " ++ show(o) ++ "\t" else "" endif ++ show(shift_name[fix(assignment[o, h])]) ++ "\t" | o in Operators, h in Hours ] ++ ["\n\n"];
