# PID Controller
class PID_TP:
    def __init__(self, Kp, Ki, Kd, bias=0, dt=0.25, cv_low_limit=0, cv_high_limit=76.2,
                 min_s=-100, max_s=100, min_i=-100, max_i=100, min_cv=0, max_cv=100,
                 initial_u=0.0, initial_error=0.0, deadband=0):
        
        # Initialize PID constants
        self.Kp = Kp
        self.Ki = Ki
        self.Kd = Kd
        self.bias = bias
        self.min_s = min_s  # Engineering unit min
        self.max_s = max_s  # Engineering unit max
        self.min_i = min_i  # Unscaled min
        self.max_i = max_i  # Unscaled max
        self.cv_low = cv_low_limit  # Lower limitation on CV in per cent
        self.cv_high = cv_high_limit  # Upper limitation on CV in per cent
        self.min_cv = min_cv  # Min CV (at 0%)
        self.max_cv = max_cv  # Max CV (at 100%)
        self.dt = dt  # Sampling period
        self.doe = 0    # Derivative of (0 = PV, 1 = Error)
        self.deadband = deadband  # Deadband range
        
        # Internal variables to store previous states
        self.prev_error = 0        
        self.integral = 100*(initial_u - min_cv)/(max_cv-min_cv)+(Kp+Ki*dt)*self._scale_error(initial_error) # Back-calculation        
        self.prev_pv = 0  # Previous process variable for derivative calculation
        self.prev_D = 0      # Previous derivative term, used for D-part filtering
        self.u = initial_u
        
    def _scale_pv(self, PV):
        """ Convert Binary to Engineering units"""
        return (PV - self.min_i) * (self.max_s - self.min_s) / (self.max_i - self.min_i) + self.min_s

    def _scale_error(self, error):
        """ Convert Units to per cent"""
        return error * 100 / (self.max_s - self.min_s)

    def _scale_output(self, cv_per_cent):
        """ Convert per cent to units"""
        return cv_per_cent * (self.max_cv - self.min_cv) / 100 + self.min_cv

    def compute(self, SP, PV):
        # Scale process value        
        PV = self._scale_pv(PV)      
    
        # Calculate the error using the standard definition (SP - PV)
        
         # Apply deadband
        if  abs(SP-PV) < self.deadband:
            return self._scale_output(self.u)
            
        else:
            self.error = self._scale_error(SP - PV)  # Error in per cent
            
            
            # Calculate the Proportional term
            P = self.Kp * self.error
        
            # Calculate the Integral term
            I = (self.Ki * self.error * self.dt) + self.integral
        
            # Calculate the Derivative term (using PV, not error)
            # Filtering
            if self.Kd > 0:
                alpha = 1/(16*self.dt/self.Kd+1)        # 16 - the magic filter constant given the Rockwell gods
            else:
                alpha = 0
            # Derivative of 
            if self.doe == 0:   # Derivative of PV
                Q = PV
                Q_prev = self.prev_pv 
            else:               # Derivative of Error
                Q = self.error
                Q_prev = self.prev_error
        
            D = (1-alpha)*self.Kd*(Q-Q_prev)/self.dt + alpha*self.prev_D
        
            # Calculate the control variable (CV) with Bias
            self.u = P + I + self.bias #-D
            
            # Output limiting and anti-windup (clamping)
            if self.u < self.cv_low:
                self.u = self.cv_low
            elif self.u > self.cv_high:
                self.u = self.cv_high
            else:
                self.integral = I
        
            # Update previous error and process variable
            self.prev_error = self.error
            self.prev_pv = PV
            self.prev_D = D

            # Scale output
            return self._scale_output(self.u)