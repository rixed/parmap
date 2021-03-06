(**************************************************************************)
(* Sample use of Parmap, a simple library to perform Map computations on  *)
(* a multi-core                                                           *)
(*                                                                        *)
(*  Author(s):  Roberto Di Cosmo                                          *)
(*                                                                        *)
(*  This program is free software: you can redistribute it and/or modify  *)
(*  it under the terms of the GNU General Public License as               *)
(*  published by the Free Software Foundation, either version 2 of the    *)
(*  License, or (at your option) any later version.                       *)
(**************************************************************************)

open Parmap

let initsegm n = let rec aux acc = function 0 -> acc | n -> aux (n::acc) (n-1) in aux [] n
;;

let compute p = 
  let r=ref 1 in 
  for i = 1 to 80000 do 
    r:= !r+(p*p)-(p*(p-1))
  done;
  !r
;;

let scale_test iter nprocmin nprocmax =
  Printf.eprintf "Testing scalability with %d iterations on %d*2 to %d*2 cores\n" iter nprocmin nprocmax;
  let l = initsegm 20000 in
  let cl,tseq =  
    let d=Unix.gettimeofday() in
    let l' = List.fold_right (+) (List.map compute l) 0
    in l',(Unix.gettimeofday() -. d)
  in
  Printf.eprintf "Sequential execution takes %f seconds\n" tseq;
  for i = nprocmin to nprocmax do
    let tot=ref 0.0 in
    for j=1 to iter do
      let d=Unix.gettimeofday() in
      let cl'=parmapfold ~ncores:(i*2) ~chunksize:100 compute (L l) (+) 0 (+) in
      tot:=!tot+.(Unix.gettimeofday()-.d);
      if cl<>cl' then Printf.eprintf "Parmap failure: result mismatch\n"
    done;
    let speedup=tseq /. (!tot /. (float iter)) in 
    Printf.eprintf "Speedup with %d cores (average on %d iterations): %f (tseq=%f, tpar=%f)\n" (i*2) iter speedup tseq (!tot /. (float iter))
  done
;;

scale_test 2 1 10;;

