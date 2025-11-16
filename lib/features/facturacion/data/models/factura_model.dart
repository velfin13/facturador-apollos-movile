import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/factura.dart';

part 'factura_model.g.dart';

@JsonSerializable(explicitToJson: true)
class FacturaModel extends Factura {
  @JsonKey(name: 'items')
  final List<ItemFacturaModel> itemsModel;

  const FacturaModel({
    required super.id,
    required super.clienteNombre,
    required super.total,
    required super.fecha,
    required this.itemsModel,
  }) : super(items: itemsModel);

  factory FacturaModel.fromJson(Map<String, dynamic> json) =>
      _$FacturaModelFromJson(json);

  Map<String, dynamic> toJson() => _$FacturaModelToJson(this);

  factory FacturaModel.fromEntity(Factura factura) {
    return FacturaModel(
      id: factura.id,
      clienteNombre: factura.clienteNombre,
      total: factura.total,
      fecha: factura.fecha,
      itemsModel: factura.items
          .map(
            (item) => ItemFacturaModel(
              descripcion: item.descripcion,
              cantidad: item.cantidad,
              precioUnitario: item.precioUnitario,
            ),
          )
          .toList(),
    );
  }
}

@JsonSerializable()
class ItemFacturaModel extends ItemFactura {
  const ItemFacturaModel({
    required super.descripcion,
    required super.cantidad,
    required super.precioUnitario,
  });

  factory ItemFacturaModel.fromJson(Map<String, dynamic> json) =>
      _$ItemFacturaModelFromJson(json);

  Map<String, dynamic> toJson() => _$ItemFacturaModelToJson(this);
}
