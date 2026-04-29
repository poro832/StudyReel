class Quiz {
  final String question;
  final List<String> options;
  final int answerIndex;
  final String hint;

  const Quiz({
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.hint,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
        question: json['question'] as String,
        options: List<String>.from(json['options'] as List),
        answerIndex: json['answerIndex'] as int,
        hint: json['hint'] as String,
      );

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'answerIndex': answerIndex,
        'hint': hint,
      };
}

class StudyCard {
  final String id;
  final String topic;
  final String title;
  final String oneLiner;
  final List<String> points;
  final List<String> keywords;
  final Quiz? quiz;
  final bool isBookmarked;

  const StudyCard({
    required this.id,
    required this.topic,
    required this.title,
    required this.oneLiner,
    required this.points,
    required this.keywords,
    this.quiz,
    this.isBookmarked = false,
  });

  factory StudyCard.fromJson(Map<String, dynamic> json) => StudyCard(
        id: json['id'] as String,
        topic: json['topic'] as String,
        title: json['title'] as String,
        oneLiner: json['oneLiner'] as String,
        points: List<String>.from(json['points'] as List),
        keywords: List<String>.from(json['keywords'] as List),
        quiz: json['quiz'] != null
            ? Quiz.fromJson(json['quiz'] as Map<String, dynamic>)
            : null,
        isBookmarked: json['isBookmarked'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'topic': topic,
        'title': title,
        'oneLiner': oneLiner,
        'points': points,
        'keywords': keywords,
        if (quiz != null) 'quiz': quiz!.toJson(),
        'isBookmarked': isBookmarked,
      };

  StudyCard copyWith({bool? isBookmarked}) => StudyCard(
        id: id,
        topic: topic,
        title: title,
        oneLiner: oneLiner,
        points: points,
        keywords: keywords,
        quiz: quiz,
        isBookmarked: isBookmarked ?? this.isBookmarked,
      );
}
