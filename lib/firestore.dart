import'package:cloud_firestore/cloud_firestore.dart';


class FireStoreServices{
  final CollectionReference notes=FirebaseFirestore.instance.collection('collectionPath');


  Future<void> addNote(String s){
    return notes.add({'note':s});
  }

  //Stream<Querysnapshot> getnordesfromstream(){
    
  //}
  




}



