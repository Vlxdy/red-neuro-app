class LoginOffline {
  String nroDocumento;
  String placa;

  LoginOffline(this.nroDocumento, this.placa);

  static empty() => LoginOffline('', '');

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['nroDocumento'] = nroDocumento;
    data['placa'] = placa;
    return data;
  }
}
