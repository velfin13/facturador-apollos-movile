import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/factura.dart';

part 'factura_model.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class FacturaModel extends Factura {
  @JsonKey(name: 'idSysFcCabVenta')
  final String idSysFcCabVenta;

  @JsonKey(name: 'idSysPeriodo')
  final String idSysPeriodo;

  @JsonKey(name: 'idSysFcCliente')
  final String idSysFcCliente;

  @JsonKey(name: 'detalles')
  final List<ItemFacturaModel> detalles;

  @JsonKey(name: 'formasPago')
  final List<FormaPagoModel> formasPagoModel;

  const FacturaModel({
    required this.idSysFcCabVenta,
    required this.idSysPeriodo,
    super.tipo,
    required super.fecha,
    required this.idSysFcCliente,
    super.clienteNombre,
    super.numFact,
    super.observacion,
    required super.total,
    required this.detalles,
    required this.formasPagoModel,
  }) : super(
         id: idSysFcCabVenta,
         periodo: idSysPeriodo,
         clienteId: idSysFcCliente,
         items: detalles,
         formasPago: formasPagoModel,
       );

  factory FacturaModel.fromJson(Map<String, dynamic> json) {
    // Los detalles pueden venir null en la lista de facturas
    final detallesList = json['detalles'] as List<dynamic>?;
    final detalles =
        detallesList
            ?.map((e) => ItemFacturaModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Las formas de pago también pueden ser null
    final formasPagoList = json['formasPago'] as List<dynamic>?;
    final formasPago =
        formasPagoList
            ?.map((e) => FormaPagoModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return FacturaModel(
      idSysFcCabVenta: json['idSysFcCabVenta'] as String,
      idSysPeriodo: json['idSysPeriodo'] as String,
      tipo: json['tipo'] as String?,
      fecha: DateTime.parse(json['fecha'] as String),
      idSysFcCliente: json['idSysFcCliente'] as String,
      clienteNombre: json['nombreCliente'] as String?,
      numFact: json['numFact'] as String?,
      observacion: json['observacion'] as String?,
      total: (json['total'] as num).toDouble(),
      detalles: detalles,
      formasPagoModel: formasPago,
    );
  }

  Map<String, dynamic> toJson() => _$FacturaModelToJson(this);

  factory FacturaModel.fromEntity(Factura factura) {
    return FacturaModel(
      idSysFcCabVenta: factura.id,
      idSysPeriodo: factura.periodo,
      tipo: factura.tipo,
      fecha: factura.fecha,
      idSysFcCliente: factura.clienteId,
      clienteNombre: factura.clienteNombre,
      numFact: factura.numFact,
      observacion: factura.observacion,
      total: factura.total,
      detalles: factura.items
          .map((item) => ItemFacturaModel.fromEntity(item))
          .toList(),
      formasPagoModel: factura.formasPago
          .map((fp) => FormaPagoModel.fromEntity(fp))
          .toList(),
    );
  }
}

@JsonSerializable(includeIfNull: false)
class ItemFacturaModel extends ItemFactura {
  @JsonKey(name: 'idSysInProducto')
  final String idSysInProducto;

  const ItemFacturaModel({
    required this.idSysInProducto,
    super.productoNombre,
    required super.cantidad,
    required super.valor,
    super.descuentoPorcentaje,
    super.bodegaId,
  }) : super(productoId: idSysInProducto);

  factory ItemFacturaModel.fromJson(Map<String, dynamic> json) =>
      _$ItemFacturaModelFromJson(json);

  Map<String, dynamic> toJson() => _$ItemFacturaModelToJson(this);

  factory ItemFacturaModel.fromEntity(ItemFactura item) {
    return ItemFacturaModel(
      idSysInProducto: item.productoId,
      productoNombre: item.productoNombre,
      cantidad: item.cantidad,
      valor: item.valor,
      descuentoPorcentaje: item.descuentoPorcentaje,
      bodegaId: item.bodegaId,
    );
  }
}

@JsonSerializable(includeIfNull: false)
class FormaPagoModel extends FormaPago {
  @JsonKey(name: 'idSysFcFormaPago')
  final String idSysFcFormaPago;

  const FormaPagoModel({
    required this.idSysFcFormaPago,
    super.formaPagoNombre,
    required super.valor,
    super.numero,
    super.referencia,
    super.fechaVence,
  }) : super(formaPagoId: idSysFcFormaPago);

  factory FormaPagoModel.fromJson(Map<String, dynamic> json) =>
      _$FormaPagoModelFromJson(json);

  Map<String, dynamic> toJson() => _$FormaPagoModelToJson(this);

  factory FormaPagoModel.fromEntity(FormaPago formaPago) {
    return FormaPagoModel(
      idSysFcFormaPago: formaPago.formaPagoId,
      formaPagoNombre: formaPago.formaPagoNombre,
      valor: formaPago.valor,
      numero: formaPago.numero,
      referencia: formaPago.referencia,
      fechaVence: formaPago.fechaVence,
    );
  }
}
