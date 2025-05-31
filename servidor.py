from flask import Flask, request

app = Flask(__name__)

@app.route('/aviso')
def aviso():
  mensagem = request.args.get('mensagem', 'Sem mensagem')
  print(f"Recebido: {mensagem}")
  return 'OK'

if __name__ == '__main__':
  app.run(host='0.0.0.0', port=5000)
