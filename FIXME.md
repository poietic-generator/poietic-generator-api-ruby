FIXME
=====

* Pb entre l'history et le viewer (il faut distinguer les modes)
* Dans le viewer/history, garder une référence temporelle et calculer
  l'offset entre le serveur et le client.
* Corriger les requtes : passer local_time - offset comme valeur de "since"
  => corrige viewer (?)
* quand-est-ce qu'on envoie la prochaine requete ?
  => dans le cas du viewer : on s'en fout, on verra bien
  => dans le cas de l'history : 
     - je demande une date, et je demande une durée
     => selon le facteur vitesse, j'en déduis le moment de ma prochaine requete

