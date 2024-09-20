class BookingState{
  final String? date;
  final String? is_approved;
   BookingState({
    this.date,
    this.is_approved,
   });
   BookingState.fromJson(Map<String, dynamic> json)
      : date = json['date'] as String?,
        is_approved = json['is_approved'] as String?;
       
  Map<String, dynamic> toJson() => {
    
        'date': date,
        'is_approved': is_approved,
        
      };
    BookingState copyWith({
    String? date,
    String? is_approved,
   
  }){
    return BookingState(
      date: date ?? this.date,
      is_approved: is_approved ?? this.is_approved,
     
    );
  }
}
