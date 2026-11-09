'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { prepareWriteData } = require('./importar_exercicios.js');

const imported = {
  name: 'Barbell Bench Press',
  nameNormalized: 'barbell bench press',
  instructions: 'English instructions',
  imageUrl: 'https://example.org/new.webp',
  muscleGroup: 'Peito',
};

test('v6: reimportacao nao apaga nome editorial em portugues', () => {
  const saved = {
    language: '',
    name: 'Supino reto com barra',
    nameReviewStatus: 'editorial_pending_review',
  };
  const update = prepareWriteData(imported, saved);
  assert.equal(Object.hasOwn(update, 'name'), false);
  assert.equal(Object.hasOwn(update, 'nameNormalized'), false);
  assert.equal(update.imageUrl, imported.imageUrl);
  assert.equal(update.instructions, 'English instructions');
});

test('traducao completa preserva nome e instrucao', () => {
  const update = prepareWriteData(imported, { language: 'pt-BR' });
  assert.equal(Object.hasOwn(update, 'name'), false);
  assert.equal(Object.hasOwn(update, 'nameNormalized'), false);
  assert.equal(Object.hasOwn(update, 'instructions'), false);
  assert.equal(update.imageUrl, imported.imageUrl);
});

test('base original sem traducao continua atualizavel', () => {
  const update = prepareWriteData(imported, { language: 'en' });
  assert.deepEqual(update, imported);
});

test('nome oficialmente revisado tambem e protegido', () => {
  const update = prepareWriteData(imported, {nameReviewStatus: 'reviewed'});
  assert.equal(Object.hasOwn(update, 'name'), false);
});

test('documento ainda nao existente recebe todos os campos', () => {
  const update = prepareWriteData(imported, undefined);
  assert.deepEqual(update, imported);
});
