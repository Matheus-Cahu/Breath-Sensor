from flask import Flask, jsonify, request

app = Flask(__name__)

# Estado atual do sensor
sensor_status = False

@app.route('/')
def index():
    return 'Servidor Flask rodando!'

@app.route('/aviso')
def aviso():
    global sensor_status
    # Permite mudar o status com ?ativo=true ou ?ativo=false
    ativo = request.args.get('ativo')
    if ativo is not None:
        sensor_status = ativo.lower() == 'true'
    return jsonify({'status': sensor_status})  # <-- Responde JSON correto

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
