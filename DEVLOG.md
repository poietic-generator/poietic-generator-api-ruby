
29/06/2014
----------

Je viens d'ajouter la création automatique de board lorsqu'on se connecte sur board_group.
La question qui se pose est d'afficher si le group est live ou pas (dans la liste online/cli)
et vérifier que cela fonctionne correctement.

Une fois que ca sera bon, il faudra gérer le nombre d'utilisateurs lors du jeu et éventuellement
afficher cela dans la liste.

----

La création de board live semble fonctionner. Il reste à détruire/clore ces boards de
sessions lorsque le nombre d'utilisateurs chute en dessous de zéro.

Ensuite on fera un peu de polish pour afficher le nombre d'utilisateurs live.

----

Je cherche un moyen de faire tourner un scheduler simple (snas avoir à gérer moi meme les threads).
https://jkraemer.net/running-rufus-scheduler-in-a-unicorn-rails-app semble pas mal. A tester.


