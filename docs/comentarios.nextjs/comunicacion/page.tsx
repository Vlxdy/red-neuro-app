'use client'
import { Card, CardContent, Typography } from '@mui/material'
import { useAuth } from '@/context/AuthProvider'
import SeccionComentarios from './components/SeccionComentarios'

export default function Comunición() {
  const { rolUsuario } = useAuth()

  const idHistoriaClinica = rolUsuario?.idHistoriaClinica

  return (
    <>
      <title>Mis actividades</title>
      {idHistoriaClinica ? (
        <>
          <SeccionComentarios idHistoriaClinica={idHistoriaClinica} />
        </>
      ) : (
        <Card>
          <CardContent sx={{ textAlign: 'center' }}>
            <Typography variant="h6" component="div">
              Aun no se ha realizado ninguna cita nutricional. Aun no se le ha
              asignado un profesional de la salud, por favor comuniquese con el
              administrador
            </Typography>
          </CardContent>
        </Card>
      )}
    </>
  )
}
