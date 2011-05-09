

let dir_c x = match x with
        (0,1) -> "^"
        | (0,-1) -> "v"
        | (-1,0) -> "<-"
        | (1,0) -> "->"
        | _ -> "x"
;;

(* spirale pos v step -> pos v step *)
let rec spirale_rec pos dir idx idx2 = 
        let pos_x, pos_y = pos in
        let dir_x, dir_y = dir in
        let pos_next = (pos_x + dir_x, pos_y + dir_y) 
        in
        let dir_next = 
                if (abs pos_x) = (abs pos_y) then (- dir_y, dir_x)
                else dir
        in
        if idx > 0 then 
                        spirale_rec pos_next dir_next (idx-1) (idx2 + 1)
        else begin
                Printf.printf "Spirale (%d,%d) -> %d\n" pos_x pos_y idx2 ; 
                Printf.printf "  dir = %s\n" (dir_c dir);
                pos, dir, idx, idx2
        end
;;

let spirale idx = 
        let pos, dir, idx,idx2 = spirale_rec (0,0) (1,0) idx 0 in
        pos
;;


let x = ref 0
in
while (!x < 10) do
        ignore ( spirale !x );
        x := ( !x + 1 );
done
;;

