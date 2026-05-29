from flask import Flask, render_template, request, jsonify, redirect, url_for, session
from flask_sqlalchemy import SQLAlchemy
from flask_bcrypt import Bcrypt
from functools import wraps
import os

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'dev-secret-key')
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get(
    'DATABASE_URL',
    'postgresql://counter:counter@localhost:5432/counterdb'
)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)
bcrypt = Bcrypt(app)


class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    counters = db.relationship('Counter', backref='user', lazy=True)

    def set_password(self, password):
        self.password_hash = bcrypt.generate_password_hash(password).decode('utf-8')

    def check_password(self, password):
        return bcrypt.check_password_hash(self.password_hash, password)


class Counter(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), nullable=False, default='My Counter')
    value = db.Column(db.Integer, nullable=False, default=0)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)


def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'user_id' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated


@app.route('/')
def index():
    if 'user_id' in session:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))


@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        if User.query.filter_by(username=username).first():
            return render_template('register.html', error='Username already exists')
        user = User(username=username)
        user.set_password(password)
        db.session.add(user)
        db.session.commit()
        counter = Counter(name='My Counter', value=0, user_id=user.id)
        db.session.add(counter)
        db.session.commit()
        session['user_id'] = user.id
        session['username'] = user.username
        return redirect(url_for('dashboard'))
    return render_template('register.html')


@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        user = User.query.filter_by(username=username).first()
        if user and user.check_password(password):
            session['user_id'] = user.id
            session['username'] = user.username
            return redirect(url_for('dashboard'))
        return render_template('login.html', error='Invalid credentials')
    return render_template('login.html')


@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))


@app.route('/dashboard')
@login_required
def dashboard():
    counters = Counter.query.filter_by(user_id=session['user_id']).all()
    return render_template('dashboard.html', counters=counters, username=session['username'])


@app.route('/api/counter/<int:counter_id>/up', methods=['POST'])
@login_required
def count_up(counter_id):
    counter = Counter.query.filter_by(id=counter_id, user_id=session['user_id']).first_or_404()
    counter.value += 1
    db.session.commit()
    return jsonify({'value': counter.value})


@app.route('/api/counter/<int:counter_id>/down', methods=['POST'])
@login_required
def count_down(counter_id):
    counter = Counter.query.filter_by(id=counter_id, user_id=session['user_id']).first_or_404()
    counter.value -= 1
    db.session.commit()
    return jsonify({'value': counter.value})


@app.route('/api/counter/<int:counter_id>/reset', methods=['POST'])
@login_required
def count_reset(counter_id):
    counter = Counter.query.filter_by(id=counter_id, user_id=session['user_id']).first_or_404()
    counter.value = 0
    db.session.commit()
    return jsonify({'value': counter.value})


@app.route('/api/counter/<int:counter_id>/set', methods=['POST'])
@login_required
def count_set(counter_id):
    counter = Counter.query.filter_by(id=counter_id, user_id=session['user_id']).first_or_404()
    data = request.get_json()
    try:
        counter.value = int(data['value'])
        db.session.commit()
        return jsonify({'value': counter.value})
    except (KeyError, ValueError):
        return jsonify({'error': 'Invalid value'}), 400


@app.route('/api/counter', methods=['POST'])
@login_required
def create_counter():
    data = request.get_json()
    counter = Counter(
        name=data.get('name', 'New Counter'),
        value=data.get('start', 0),
        user_id=session['user_id']
    )
    db.session.add(counter)
    db.session.commit()
    return jsonify({'id': counter.id, 'name': counter.name, 'value': counter.value})


@app.route('/api/counter/<int:counter_id>', methods=['DELETE'])
@login_required
def delete_counter(counter_id):
    counter = Counter.query.filter_by(id=counter_id, user_id=session['user_id']).first_or_404()
    db.session.delete(counter)
    db.session.commit()
    return jsonify({'success': True})


if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(host='0.0.0.0', port=5000)
