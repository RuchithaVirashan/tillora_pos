/// Reason lists staff pick from at the till, stored as
/// `posMessages.parameter`.
enum MessageType {
  voidLine('Void Line', 'voiditem'),
  voidSale('Void Sale', 'voidsale'),
  noSale('No Sale', 'nosale'),
  ageRefusal('Age Refusal', 'agerefusal');

  const MessageType(this.label, this.key);
  final String label;
  final String key;
}

typedef PosMessage = ({int id, String text});
