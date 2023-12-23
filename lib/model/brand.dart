import 'label_design.dart';

class Brand {
  final String name;
  final LabelDesign labelDesign;

  const Brand(this.name, {this.labelDesign = const LabelDesign(fontSize: 16)});
}
