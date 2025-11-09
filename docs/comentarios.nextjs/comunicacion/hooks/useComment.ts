import { useCallback, useState } from 'react'
import { ComentarioReadType } from '../types/comentario.type'

const cloneComentario = (
  comentario: ComentarioReadType
): ComentarioReadType => ({
  ...comentario,
  archivos: comentario.archivos?.map((archivo) => ({ ...archivo })) ?? [],
  respuestas: comentario.respuestas?.map(cloneComentario) ?? [],
})

const resolveSortValue = (comentario: ComentarioReadType): number => {
  const numericId = Number(comentario.id)
  if (!Number.isNaN(numericId)) {
    return numericId
  }

  const timestamp = new Date(comentario.fechaCreacion ?? '').getTime()
  return Number.isNaN(timestamp) ? 0 : timestamp
}

const sortComentarios = (
  comentarios: ComentarioReadType[]
): ComentarioReadType[] =>
  comentarios
    .map((comentario) => ({
      ...comentario,
      respuestas: comentario.respuestas?.length
        ? sortComentarios(comentario.respuestas)
        : [],
    }))
    .sort((a, b) => resolveSortValue(b) - resolveSortValue(a))

const insertComentario = (
  comentarios: ComentarioReadType[],
  comentario: ComentarioReadType
): ComentarioReadType[] => {
  const normalizado = cloneComentario(comentario)

  if (!normalizado.idComentarioPadre) {
    const sinDuplicados = comentarios.filter(
      (item) => item.id !== normalizado.id
    )
    return sortComentarios([...sinDuplicados, normalizado])
  }

  return comentarios.map((item) => {
    if (item.id === normalizado.idComentarioPadre) {
      const respuestas = item.respuestas ?? []
      const sinDuplicados = respuestas.filter(
        (res) => res.id !== normalizado.id
      )
      return {
        ...item,
        respuestas: sortComentarios([...sinDuplicados, normalizado]),
      }
    }

    if (item.respuestas?.length) {
      return {
        ...item,
        respuestas: insertComentario(item.respuestas, normalizado),
      }
    }

    return item
  })
}

const updateComentarioById = (
  comentarios: ComentarioReadType[],
  idComentario: string,
  cambios: Partial<ComentarioReadType>
): ComentarioReadType[] => {
  let seModifico = false

  const actualizados = comentarios.map((comentario) => {
    if (comentario.id === idComentario) {
      seModifico = true
      return {
        ...comentario,
        ...cambios,
        archivos: cambios.archivos ?? comentario.archivos ?? [],
        respuestas: cambios.respuestas ?? comentario.respuestas ?? [],
      }
    }

    if (comentario.respuestas?.length) {
      const respuestasActualizadas = updateComentarioById(
        comentario.respuestas,
        idComentario,
        cambios
      )
      if (respuestasActualizadas !== comentario.respuestas) {
        seModifico = true
        return {
          ...comentario,
          respuestas: respuestasActualizadas,
        }
      }
    }

    return comentario
  })

  return seModifico ? sortComentarios(actualizados) : comentarios
}

const removeComentarioById = (
  comentarios: ComentarioReadType[],
  idComentario: string
): ComentarioReadType[] => {
  const filtrados = comentarios
    .filter((comentario) => comentario.id !== idComentario)
    .map((comentario) => ({
      ...comentario,
      respuestas: comentario.respuestas?.length
        ? removeComentarioById(comentario.respuestas, idComentario)
        : [],
    }))

  if (filtrados.length === comentarios.length) {
    return comentarios
  }

  return filtrados
}

const findComentarioById = (
  comentarios: ComentarioReadType[],
  idComentario: string
): ComentarioReadType | undefined => {
  for (const comentario of comentarios) {
    if (comentario.id === idComentario) {
      return comentario
    }

    if (comentario.respuestas?.length) {
      const encontrado = findComentarioById(comentario.respuestas, idComentario)
      if (encontrado) {
        return encontrado
      }
    }
  }

  return undefined
}

export const useComment = () => {
  const [comentarios, setComentarios] = useState<ComentarioReadType[]>([])

  const initData = (comentariosIniciales: ComentarioReadType[] = []) => {
    setComentarios(sortComentarios(comentariosIniciales.map(cloneComentario)))
  }

  const agregarCommentario = (comentario: ComentarioReadType) => {
    setComentarios((prevComentarios) =>
      insertComentario(prevComentarios, comentario)
    )
  }

  const actualizarComentario = (
    idComentario: string,
    cambios: Partial<ComentarioReadType>
  ) => {
    setComentarios((prevComentarios) =>
      updateComentarioById(prevComentarios, idComentario, cambios)
    )
  }

  const eliminarComentario = (idComentario: string) => {
    setComentarios((prevComentarios) =>
      removeComentarioById(prevComentarios, idComentario)
    )
  }

  const responderComentario = (
    idComentarioPadre: string,
    respuesta: ComentarioReadType
  ) => {
    setComentarios((prevComentarios) =>
      insertComentario(prevComentarios, {
        ...respuesta,
        idComentarioPadre,
      })
    )
  }

  const actualizarRespuesta = (
    idComentario: string,
    idRespuesta: string,
    cambios: Partial<ComentarioReadType>
  ) => {
    setComentarios((prevComentarios) =>
      updateComentarioById(prevComentarios, idRespuesta, {
        ...cambios,
        idComentarioPadre: idComentario,
      })
    )
  }

  const eliminarRespuesta = (idComentario: string, idRespuesta: string) => {
    setComentarios((prevComentarios) =>
      removeComentarioById(prevComentarios, idRespuesta)
    )
  }

  const adicionarComentarios = (
    comentariosNuevos: ComentarioReadType[] = []
  ) => {
    if (!comentariosNuevos.length) {
      return
    }

    setComentarios((prevComentarios) =>
      comentariosNuevos.reduce(
        (acumulador, comentario) => insertComentario(acumulador, comentario),
        prevComentarios
      )
    )
  }

  const obtenerComentarioPorId = useCallback(
    (idComentario: string) => findComentarioById(comentarios, idComentario),
    [comentarios]
  )

  return {
    comentarios,
    initData,
    agregarCommentario,
    actualizarComentario,
    actualizarRespuesta,
    eliminarComentario,
    responderComentario,
    eliminarRespuesta,
    adicionarComentarios,
    obtenerComentarioPorId,
  }
}
