db.pedidos.insertMany([
  {
    "_id": 10108,
    "fecha": ISODate("2026-09-28T20:41:09.710Z"),
    "estado": "CONFIRMADO",
    "forma_pago": "EFECTIVO",
    "total": 8930.28,
    "usuario": { "id_usuario": 11 },
    "detalle_pedido": [
      { "id_detalle": 249451, "cantidad": 7, "precio_unitario": 517.80, "subtotal": 3624.60, "producto": { "id_producto": 36 } },
      { "id_detalle": 249452, "cantidad": 8, "precio_unitario": 267.28, "subtotal": 2138.24, "producto": { "id_producto": 37 } },
      { "id_detalle": 249453, "cantidad": 4, "precio_unitario": 687.49, "subtotal": 2749.96, "producto": { "id_producto": 38 } },
      { "id_detalle": 249454, "cantidad": 5, "precio_unitario": 392.08, "subtotal": 1960.40, "producto": { "id_producto": 39 } },
      { "id_detalle": 249455, "cantidad": 1, "precio_unitario": 417.48, "subtotal": 417.48, "producto": { "id_producto": 40 } }
    ]
  },
  {
    "_id": 10109,
    "fecha": ISODate("2026-09-28T20:41:09.710Z"),
    "estado": "CANCELADO",
    "forma_pago": "EFECTIVO",
    "total": 12361.07,
    "usuario": { "id_usuario": 9 },
    "detalle_pedido": [
      { "id_detalle": 249456, "cantidad": 8, "precio_unitario": 655.16, "subtotal": 5241.28, "producto": { "id_producto": 41 } },
      { "id_detalle": 249457, "cantidad": 7, "precio_unitario": 156.29, "subtotal": 1094.03, "producto": { "id_producto": 42 } },
      { "id_detalle": 249458, "cantidad": 6, "precio_unitario": 161.93, "subtotal": 971.58, "producto": { "id_producto": 43 } },
      { "id_detalle": 249459, "cantidad": 2, "precio_unitario": 1012.85, "subtotal": 2025.70, "producto": { "id_producto": 44 } },
      { "id_detalle": 249460, "cantidad": 8, "precio_unitario": 378.56, "subtotal": 3028.48, "producto": { "id_producto": 45 } }
    ]
  },
  {
    "_id": 10110,
    "fecha": ISODate("2026-09-28T20:41:09.710Z"),
    "estado": "PENDIENTE",
    "forma_pago": "TARJETA",
    "total": 16790.59,
    "usuario": { "id_usuario": 20 },
    "detalle_pedido": [
      { "id_detalle": 249461, "cantidad": 5, "precio_unitario": 566.25, "subtotal": 2831.25, "producto": { "id_producto": 46 } },
      { "id_detalle": 249462, "cantidad": 6, "precio_unitario": 577.64, "subtotal": 3465.84, "producto": { "id_producto": 47 } }
    ]
  },
  {
    "_id": 10111,
    "fecha": ISODate("2026-09-28T20:41:09.710Z"),
    "estado": "PENDIENTE",
    "forma_pago": "TRANSFERENCIA",
    "total": 14642.34,
    "usuario": { "id_usuario": 17 },
    "detalle_pedido": [
      { "id_detalle": 249466, "cantidad": 4, "precio_unitario": 351.40, "subtotal": 1405.60, "producto": { "id_producto": 1 } },
      { "id_detalle": 249467, "cantidad": 8, "precio_unitario": 725.71, "subtotal": 5805.68, "producto": { "id_producto": 2 } },
      { "id_detalle": 249468, "cantidad": 2, "precio_unitario": 624.57, "subtotal": 1249.14, "producto": { "id_producto": 3 } },
      { "id_detalle": 249469, "cantidad": 1, "precio_unitario": 241.08, "subtotal": 241.08, "producto": { "id_producto": 4 } },
      { "id_detalle": 249470, "cantidad": 6, "precio_unitario": 990.14, "subtotal": 5940.84, "producto": { "id_producto": 5 } }
    ]
  },
  {
    "_id": 10112,
    "fecha": ISODate("2026-09-28T20:41:09.710Z"),
    "estado": "PENDIENTE",
    "forma_pago": "TARJETA",
    "total": 25380.85,
    "usuario": { "id_usuario": 17 },
    "detalle_pedido": [
      { "id_detalle": 249471, "cantidad": 9, "precio_unitario": 722.41, "subtotal": 6501.69, "producto": { "id_producto": 6 } },
      { "id_detalle": 249472, "cantidad": 10, "precio_unitario": 226.56, "subtotal": 2265.60, "producto": { "id_producto": 7 } },
      { "id_detalle": 249473, "cantidad": 7, "precio_unitario": 957.52, "subtotal": 6702.64, "producto": { "id_producto": 8 } },
      { "id_detalle": 249474, "cantidad": 3, "precio_unitario": 365.08, "subtotal": 1095.24, "producto": { "id_producto": 9 } },
      { "id_detalle": 249475, "cantidad": 9, "precio_unitario": 979.52, "subtotal": 8815.68, "producto": { "id_producto": 10 } }
    ]
  }
]);
db.pedidos.find()   
/* SALIDA                                
{
  _id: 10108,
  fecha: ISODate('2026-09-28T20:41:09.710Z'),
  estado: 'CONFIRMADO',
  forma_pago: 'EFECTIVO',
  total: 8930.28,
  usuario: {
    id_usuario: 11
  },
  detalle_pedido: [
    {
      id_detalle: 249451,
      cantidad: 7,
      precio_unitario: 517.8,
      subtotal: 3624.6,
      producto: {
        id_producto: 36
      }
    },
    {
      id_detalle: 249452,
      cantidad: 8,
      precio_unitario: 267.28,
      subtotal: 2138.24,
      producto: {
        id_producto: 37
      }
    },
    {
      id_detalle: 249453,
      cantidad: 4,
      precio_unitario: 687.49,
      subtotal: 2749.96,
      producto: {
        id_producto: 38
      }
    },
    {
      id_detalle: 249454,
      cantidad: 5,
      precio_unitario: 392.08,
      subtotal: 1960.4,
      producto: {
        id_producto: 39
      }
    },
    {
      id_detalle: 249455,
      cantidad: 1,
      precio_unitario: 417.48,
      subtotal: 417.48,
      producto: {
        id_producto: 40
      }
    }
  ]
}
  {
  _id: 10109,
  fecha: ISODate('2026-09-28T20:41:09.710Z'),
  estado: 'CANCELADO',
  forma_pago: 'EFECTIVO',
  total: 12361.07,
  usuario: {
    id_usuario: 9
  },
  detalle_pedido: [
    {
      id_detalle: 249456,
      cantidad: 8,
      precio_unitario: 655.16,
      subtotal: 5241.28,
      producto: {
        id_producto: 41
      }
    },
    {
      id_detalle: 249457,
      cantidad: 7,
      precio_unitario: 156.29,
      subtotal: 1094.03,
      producto: {
        id_producto: 42
      }
    },
    {
      id_detalle: 249458,
      cantidad: 6,
      precio_unitario: 161.93,
      subtotal: 971.58,
      producto: {
        id_producto: 43
      }
    },
    {
      id_detalle: 249459,
      cantidad: 2,
      precio_unitario: 1012.85,
      subtotal: 2025.7,
      producto: {
        id_producto: 44
      }
    },
    {
      id_detalle: 249460,
      cantidad: 8,
      precio_unitario: 378.56,
      subtotal: 3028.48,
      producto: {
        id_producto: 45
      }
    }
  ]
}{
  _id: 10110,
  fecha: ISODate('2026-09-28T20:41:09.710Z'),
  estado: 'PENDIENTE',
  forma_pago: 'TARJETA',
  total: 16790.59,
  usuario: {
    id_usuario: 20
  },
  detalle_pedido: [
    {
      id_detalle: 249461,
      cantidad: 5,
      precio_unitario: 566.25,
      subtotal: 2831.25,
      producto: {
        id_producto: 46
      }
    },
    {
      id_detalle: 249462,
      cantidad: 6,
      precio_unitario: 577.64,
      subtotal: 3465.84,
      producto: {
        id_producto: 47
      }
    }
  ]
}{
  _id: 10111,
  fecha: ISODate('2026-09-28T20:41:09.710Z'),
  estado: 'PENDIENTE',
  forma_pago: 'TRANSFERENCIA',
  total: 14642.34,
  usuario: {
    id_usuario: 17
  },
  detalle_pedido: [
    {
      id_detalle: 249466,
      cantidad: 4,
      precio_unitario: 351.4,
      subtotal: 1405.6,
      producto: {
        id_producto: 1
      }
    },
    {
      id_detalle: 249467,
      cantidad: 8,
      precio_unitario: 725.71,
      subtotal: 5805.68,
      producto: {
        id_producto: 2
      }
    },
    {
      id_detalle: 249468,
      cantidad: 2,
      precio_unitario: 624.57,
      subtotal: 1249.14,
      producto: {
        id_producto: 3
      }
    },
    {
      id_detalle: 249469,
      cantidad: 1,
      precio_unitario: 241.08,
      subtotal: 241.08,
      producto: {
        id_producto: 4
      }
    },
    {
      id_detalle: 249470,
      cantidad: 6,
      precio_unitario: 990.14,
      subtotal: 5940.84,
      producto: {
        id_producto: 5
      }
    }
  ]
}{
  _id: 10112,
  fecha: ISODate('2026-09-28T20:41:09.710Z'),
  estado: 'PENDIENTE',
  forma_pago: 'TARJETA',
  total: 25380.85,
  usuario: {
    id_usuario: 17
  },
  detalle_pedido: [
    {
      id_detalle: 249471,
      cantidad: 9,
      precio_unitario: 722.41,
      subtotal: 6501.69,
      producto: {
        id_producto: 6
      }
    },
    {
      id_detalle: 249472,
      cantidad: 10,
      precio_unitario: 226.56,
      subtotal: 2265.6,
      producto: {
        id_producto: 7
      }
    },
    {
      id_detalle: 249473,
      cantidad: 7,
      precio_unitario: 957.52,
      subtotal: 6702.64,
      producto: {
        id_producto: 8
      }
    },
    {
      id_detalle: 249474,
      cantidad: 3,
      precio_unitario: 365.08,
      subtotal: 1095.24,
      producto: {
        id_producto: 9
      }
    },
    {
      id_detalle: 249475,
      cantidad: 9,
      precio_unitario: 979.52,
      subtotal: 8815.68,
      producto: {
        id_producto: 10
      }
    }
  ]
}*/

db.pedidos.find({ estado: "PENDIENTE" })   
/* 
SALIDA
{
  _id: 10110,
  fecha: ISODate('2026-09-28T20:41:09.710Z'),
  estado: 'PENDIENTE',
  forma_pago: 'TARJETA',
  total: 16790.59,
  usuario: {
    id_usuario: 20
  },
  detalle_pedido: [
    {
      id_detalle: 249461,
      cantidad: 5,
      precio_unitario: 566.25,
      subtotal: 2831.25,
      producto: {
        id_producto: 46
      }
    },
    {
      id_detalle: 249462,
      cantidad: 6,
      precio_unitario: 577.64,
      subtotal: 3465.84,
      producto: {
        id_producto: 47
      }
    }
  ]
}
  {
  _id: 10111,
  fecha: ISODate('2026-09-28T20:41:09.710Z'),
  estado: 'PENDIENTE',
  forma_pago: 'TRANSFERENCIA',
  total: 14642.34,
  usuario: {
    id_usuario: 17
  },
  detalle_pedido: [
    {
      id_detalle: 249466,
      cantidad: 4,
      precio_unitario: 351.4,
      subtotal: 1405.6,
      producto: {
        id_producto: 1
      }
    },
    {
      id_detalle: 249467,
      cantidad: 8,
      precio_unitario: 725.71,
      subtotal: 5805.68,
      producto: {
        id_producto: 2
      }
    },
    {
      id_detalle: 249468,
      cantidad: 2,
      precio_unitario: 624.57,
      subtotal: 1249.14,
      producto: {
        id_producto: 3
      }
    },
    {
      id_detalle: 249469,
      cantidad: 1,
      precio_unitario: 241.08,
      subtotal: 241.08,
      producto: {
        id_producto: 4
      }
    },
    {
      id_detalle: 249470,
      cantidad: 6,
      precio_unitario: 990.14,
      subtotal: 5940.84,
      producto: {
        id_producto: 5
      }
    }
  ]
}
  {
  _id: 10112,
  fecha: ISODate('2026-09-28T20:41:09.710Z'),
  estado: 'PENDIENTE',
  forma_pago: 'TARJETA',
  total: 25380.85,
  usuario: {
    id_usuario: 17
  },
  detalle_pedido: [
    {
      id_detalle: 249471,
      cantidad: 9,
      precio_unitario: 722.41,
      subtotal: 6501.69,
      producto: {
        id_producto: 6
      }
    },
    {
      id_detalle: 249472,
      cantidad: 10,
      precio_unitario: 226.56,
      subtotal: 2265.6,
      producto: {
        id_producto: 7
      }
    },
    {
      id_detalle: 249473,
      cantidad: 7,
      precio_unitario: 957.52,
      subtotal: 6702.64,
      producto: {
        id_producto: 8
      }
    },
    {
      id_detalle: 249474,
      cantidad: 3,
      precio_unitario: 365.08,
      subtotal: 1095.24,
      producto: {
        id_producto: 9
      }
    },
    {
      id_detalle: 249475,
      cantidad: 9,
      precio_unitario: 979.52,
      subtotal: 8815.68,
      producto: {
        id_producto: 10
      }
    }
  ]
}
  */
 db.pedidos.find({ "detalle_pedido.producto.id_producto": 10 })
 /*{
  _id: 10112,
  fecha: ISODate('2026-09-28T20:41:09.710Z'),
  estado: 'PENDIENTE',
  forma_pago: 'TARJETA',
  total: 25380.85,
  usuario: {
    id_usuario: 17
  },
  detalle_pedido: [
    {
      id_detalle: 249471,
      cantidad: 9,
      precio_unitario: 722.41,
      subtotal: 6501.69,
      producto: {
        id_producto: 6
      }
    },
    {
      id_detalle: 249472,
      cantidad: 10,
      precio_unitario: 226.56,
      subtotal: 2265.6,
      producto: {
        id_producto: 7
      }
    },
    {
      id_detalle: 249473,
      cantidad: 7,
      precio_unitario: 957.52,
      subtotal: 6702.64,
      producto: {
        id_producto: 8
      }
    },
    {
      id_detalle: 249474,
      cantidad: 3,
      precio_unitario: 365.08,
      subtotal: 1095.24,
      producto: {
        id_producto: 9
      }
    },
    {
      id_detalle: 249475,
      cantidad: 9,
      precio_unitario: 979.52,
      subtotal: 8815.68,
      producto: {
        id_producto: 10
      }
    }
  ]
}*/
db.pedidos.find({ total: { $gt: 20000 } }) ;
/* 
SALIDA
{
  _id: 10112,
  fecha: ISODate('2026-09-28T20:41:09.710Z'),
  estado: 'PENDIENTE',
  forma_pago: 'TARJETA',
  total: 25380.85,
  usuario: {
    id_usuario: 17
  },
  detalle_pedido: [
    {
      id_detalle: 249471,
      cantidad: 9,
      precio_unitario: 722.41,
      subtotal: 6501.69,
      producto: {
        id_producto: 6
      }
    },
    {
      id_detalle: 249472,
      cantidad: 10,
      precio_unitario: 226.56,
      subtotal: 2265.6,
      producto: {
        id_producto: 7
      }
    },
    {
      id_detalle: 249473,
      cantidad: 7,
      precio_unitario: 957.52,
      subtotal: 6702.64,
      producto: {
        id_producto: 8
      }
    },
    {
      id_detalle: 249474,
      cantidad: 3,
      precio_unitario: 365.08,
      subtotal: 1095.24,
      producto: {
        id_producto: 9
      }
    },
    {
      id_detalle: 249475,
      cantidad: 9,
      precio_unitario: 979.52,
      subtotal: 8815.68,
      producto: {
        id_producto: 10
      }
    }
  ]
}*/
